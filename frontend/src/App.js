import React from "react";
import EmployeeList from "./pages/EmployeeList";

function App() {
  return (
    <div style={{ padding: "30px", fontFamily: "Arial" }}>
      <h1 style={{ textAlign: "center" }}>Employee Management System</h1>

      <EmployeeList />
    </div>
  );
}

export default App;