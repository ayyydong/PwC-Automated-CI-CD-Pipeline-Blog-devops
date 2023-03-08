import { render, screen } from '@testing-library/react';
import App from './App';

test('renders learn react link', () => {
  render(<App />);
  const linkElement = screen.getByText(/learn react/i);
  expect(linkElement).toBeInTheDocument();
});

test('dummy test', () => {
  // uncomment the following to cause this unit test to fail
  // fail('testing pipeline fails because of test');
});
