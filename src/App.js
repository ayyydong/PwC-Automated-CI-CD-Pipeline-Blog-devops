import logo from './logo.svg';
import './App.css';

function App() {
  // Uncomment the variable below for linting to fail
  // let unused_lint_test_variable = "This is an unused variable that causes linting to fail"



  
  return (
    <div className="App">
      <header className="App-header">
        <img src={logo} className="App-logo" alt="logo" />
        <p>
          TAs change this text to check deployment: CHANGE_ME_PLS_THANKS
        </p>
        <p>
          Build ID: {process.env.REACT_APP_BUILD_ID}
        </p>
        <p>
          Short Commit SHA: {process.env.REACT_APP_SHORT_SHA}
        </p>
        <p>
          Testing environment variable: {process.env.REACT_APP_ENV}
        </p>
        <a
          className="App-link"
          href="https://reactjs.org"
          target="_blank"
          rel="noopener noreferrer"
        >
          Learn React
        </a>
      </header>
    </div>
  );
}

export default App;
