import React, { useState } from 'react';
import logo from './logo.svg';
import './App.css';

function App() {
  const [backendStatus, setBackendStatus] = useState('');

  const checkBackend = async () => {
    try {
      const response = await fetch('http://backente:8080/health');
      const data = await response.text();
      setBackendStatus(data);
    } catch (error) {
      setBackendStatus('Error: Could not connect to backente :(');
    }
  };

  return (
    <div className="App">
      <header className="App-header">
        <img src={logo} className="App-logo" alt="logo" />
        <h1 className="App-title">Hello human!</h1>
      </header>
      <p className="App-intro">
        Hazzah!! Looks like you're all set!
      </p>
      <button onClick={checkBackend}>Check Backenten Status</button>
      {backendStatus && <p>{backendStatus}</p>}
    </div>
  );
}

export default App;