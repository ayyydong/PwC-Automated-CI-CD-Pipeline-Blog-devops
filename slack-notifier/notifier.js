// code from https://alonge.medium.com/how-to-setup-slack-integration-for-google-cloud-build-using-cloud-functions-e357b580c7a1
// https://github.com/galonge/GCB-Slack-Notifier
// https://nodejs.org/api/stream.html#readablereadsize
// https://github.com/harsh4870/Cloud-build-slack-notification/blob/master/singedURL.js

const { IncomingWebhook } = require('@slack/webhook');
const {Storage} = require('@google-cloud/storage');

// variables for cloud stuff
const SLACK_WEBHOOK_URL = 'https://hooks.slack.com/services/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';
const webhook = new IncomingWebhook(SLACK_WEBHOOK_URL);
const storage = new Storage();

const cloudbuild_status_color_map = {
    SUCCESS: '#34A853', // green
    FAILURE: '#EA4335', // red
};

// variables for parsing the logs to get test results
const ONE_MEGABYTE = 1024*1024; // 1mb in bytes for reading the buffer, intentionally setting this size >> our log size
const TEST_SUITE_RESULTS_QUERY = 'Test Suites: ';
const UNIT_TEST_RESULTS_QUERY = 'Tests: ';
const TEST_COVERAGE_QUERY = 'All files';
const COVERAGE_SEPARATOR = "|";
const FAILING_TEST_CHAR = Buffer.from('4peP', 'base64').toString()
const FAILING_TEST_SEPARATOR = "Step #2: ";
const NEWLINE_CHAR = "\n";
const TEST_RESULTS_ERROR_MSG = "Tests did not run or results are unavailable";
const TEST_COVERAGE_ERROR_MSG = "Coverage did not run or results are unavailable";
const NO_FAILING_TEST_MESSAGE = "No failing tests detected";

// variables to hold output of test results
let logsReadStream;
let test_results;
let coverage_results;
let error_results;

// subscribe is the main function called by Cloud Functions.
module.exports.subscribe = pubsubMessage  => {
    const build = eventToBuild(pubsubMessage.data);

    if (Object.keys(cloudbuild_status_color_map).indexOf(build.status) === -1) return; // We don't care about this status

    logsReadStream = storage.bucket(build.logsBucket).file('log-' + build.id + '.txt').createReadStream();
    logsReadStream.on('readable', parseTestResults);
    logsReadStream.on('end', () => {
        // Send message to Slack.
        const message = createSlackMessage(build);
        (async () => {
            await webhook.send(message);
        })();
    })
};

// eventToBuild transforms pubsub event message to a build object.
const eventToBuild = (data) => {
    return JSON.parse(Buffer.from(data, 'base64').toString());
};

// parse out test results from logs
const parseTestResults = () => {
    let logs;
    let breakpoint;
    
    // Use a loop to make sure we read all currently available data from logsReadStream
    while (null !== (logs = logsReadStream.read(ONE_MEGABYTE))) {
      logs = Buffer.from(logs, 'base64').toString();
      
      // parse out test results
      let test_suite_results_index = logs.indexOf(TEST_SUITE_RESULTS_QUERY);
      breakpoint = logs.indexOf(NEWLINE_CHAR, position=test_suite_results_index);
      let test_suite_results = logs.slice(test_suite_results_index, breakpoint);

      let unit_test_results_index = logs.indexOf(UNIT_TEST_RESULTS_QUERY);
      breakpoint = logs.indexOf(NEWLINE_CHAR, position=unit_test_results_index);
      let unit_test_results = logs.slice(unit_test_results_index, breakpoint);
      test_results = formatTestResults(test_suite_results, unit_test_results);

      // parse out coverage results
      let test_coverage_index = logs.indexOf(TEST_COVERAGE_QUERY);
      breakpoint = logs.indexOf(NEWLINE_CHAR, position=test_coverage_index);
      let unformatted_coverage_results = logs.slice(test_coverage_index, breakpoint);
      coverage_results = formatCoverageResults(unformatted_coverage_results);

      // parse out any error messages from tests
      error_results = formatFailingTestMessages(logs);
    }
}

const formatTestResults = (test_suite_results, unit_test_results) => {
    if ((test_results !== undefined) && (test_results !== TEST_RESULTS_ERROR_MSG)) return test_results;
    if (test_suite_results === '' || unit_test_results === '') return TEST_RESULTS_ERROR_MSG;
    return test_suite_results + NEWLINE_CHAR + unit_test_results;
}

const formatCoverageResults = unformatted_coverage_results => {
    if ((coverage_results !== undefined) && (coverage_results !== TEST_COVERAGE_ERROR_MSG)) return coverage_results;
    if (unformatted_coverage_results === '') return TEST_COVERAGE_ERROR_MSG;
    
    const coverage_results_array = unformatted_coverage_results.split(COVERAGE_SEPARATOR);
    let results = '';
    results += 'Statements: ' + coverage_results_array[1] + '%' + NEWLINE_CHAR;
    results += 'Branches: ' + coverage_results_array[2] + '%' + NEWLINE_CHAR;
    results += 'Functions: ' + coverage_results_array[3] + '%' + NEWLINE_CHAR;
    results += 'Lines: ' + coverage_results_array[4] + '%' + NEWLINE_CHAR;
    return results;
}

const formatFailingTestMessages = logs => {
    if ((error_results !== undefined) && (error_results !== NO_FAILING_TEST_MESSAGE)) return error_results;

    let breakpoint = 0;
    let failing_test_char_index;
    let curr_error_message;
    let results = '';
  
    while((failing_test_char_index = logs.indexOf(FAILING_TEST_CHAR, breakpoint)) !== -1) {
      // grab 3 lines
      breakpoint = logs.indexOf(NEWLINE_CHAR, position=failing_test_char_index);
      breakpoint = logs.indexOf(NEWLINE_CHAR, position=breakpoint + 1);
      breakpoint = logs.indexOf(NEWLINE_CHAR, position=breakpoint + 1);
  
      curr_error_message = logs.slice(failing_test_char_index, breakpoint).split(FAILING_TEST_SEPARATOR);
      results += curr_error_message[0] + curr_error_message[2] + NEWLINE_CHAR;
    }
  
    return (results === '')? NO_FAILING_TEST_MESSAGE : results;
  }

// createSlackMessage create a message from a build object.
const createSlackMessage = build => {
    let buildId = build.id;
    let buildCommit = build.substitutions.COMMIT_SHA;
    let branch = build.substitutions.BRANCH_NAME;
    let repo = build.substitutions.REPO_NAME;

    let message = {
        text: `Build - \`${buildId}\``,
        mrkdwn: true,
        attachments: [
            {
                color: cloudbuild_status_color_map[build.status],
                title: 'View Build Logs',
                title_link: build.logUrl,
                fields: [
                    {
                        title: 'Build Status',
                        value: build.status,
                    },
                    {
                        title: 'Test results',
                        value: test_results,
                    },
                    {
                        title: 'Coverage results',
                        value: coverage_results,
                    },
                    {
                        title: 'Test error messages',
                        value: error_results,
                    },
                    {
                        title: 'Repository',
                        value: repo,
                    },
                    {
                        title: 'Branch',
                        value: branch,
                    },
                    {
                        title: 'Commit',
                        value: buildCommit,
                    },
                ],
            }
        ],
    };
    return message;
};