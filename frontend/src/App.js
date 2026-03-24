import React from "react";
import { CssBaseline, GlobalStyles, ThemeProvider, createTheme } from "@mui/material";
import EmployeePage from "./pages/EmployeePage";

const theme = createTheme({
  palette: {
    mode: "dark",
    primary: { main: "#8b5cf6" },
    secondary: { main: "#22d3ee" },
    background: { default: "#070A12" }
  },
  shape: { borderRadius: 16 },
  typography: {
    fontFamily:
      '"Inter","Segoe UI","Roboto","Oxygen","Ubuntu","Cantarell","Fira Sans","Droid Sans","Helvetica Neue",sans-serif'
  }
});

function App() {
  return (
    <ThemeProvider theme={theme}>
      <CssBaseline />
      <GlobalStyles
        styles={{
          "html, body, #root": { height: "100%" },
          body: {
            background:
              "radial-gradient(1200px 800px at 15% 10%, rgba(139,92,246,0.35), transparent 60%), radial-gradient(900px 700px at 85% 20%, rgba(34,211,238,0.25), transparent 55%), radial-gradient(900px 700px at 60% 95%, rgba(244,114,182,0.18), transparent 55%), linear-gradient(180deg, #050610 0%, #070A12 40%, #050610 100%)"
          }
        }}
      />
      <EmployeePage />
    </ThemeProvider>
  );
}

export default App;
