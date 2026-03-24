import React, { useEffect, useMemo, useState, useCallback } from "react";
import {
  getEmployees,
  createEmployee,
  deleteEmployee,
  updateEmployee
} from "../services/employeeService";

import {
  Alert,
  Avatar,
  Chip,
  Container,
  TextField,
  Button,
  Typography,
  Card,
  CardContent,
  CardActions,
  Grid,
  Box,
  Pagination,
  Paper,
  Stack,
  Tooltip,
  IconButton,
  Divider,
  InputAdornment,
  CircularProgress,
  Snackbar
} from "@mui/material";

import SearchRoundedIcon from "@mui/icons-material/SearchRounded";
import EditRoundedIcon from "@mui/icons-material/EditRounded";
import DeleteRoundedIcon from "@mui/icons-material/DeleteRounded";
import MailRoundedIcon from "@mui/icons-material/MailRounded";
import WorkRoundedIcon from "@mui/icons-material/WorkRounded";
import TrendingUpRoundedIcon from "@mui/icons-material/TrendingUpRounded";

function EmployeePage() {
  const [employees, setEmployees] = useState([]);
  const [page, setPage] = useState(0);
  const [totalPages, setTotalPages] = useState(0);
  const [keywordInput, setKeywordInput] = useState("");
  const [keyword, setKeyword] = useState("");
  const [loading, setLoading] = useState(false);

  const [form, setForm] = useState({
    name: "",
    email: "",
    role: "",
    experienceYears: 0
  });

  const [editingId, setEditingId] = useState(null);
  const [toast, setToast] = useState({ open: false, message: "", severity: "success" });

  const glassSx = useMemo(
    () => ({
      background: "rgba(255,255,255,0.08)",
      border: "1px solid rgba(255,255,255,0.16)",
      boxShadow: "0 18px 50px rgba(0,0,0,0.35)",
      backdropFilter: "blur(16px)"
    }),
    []
  );

  const loadEmployees = useCallback(async () => {
    setLoading(true);
    try {
      const res = await getEmployees(page, keyword);
      setEmployees(res.data.content || []);
      setTotalPages(res.data.totalPages || 0);
    } catch (err) {
      setToast({
        open: true,
        message: "Failed to load employees. Check backend is running.",
        severity: "error"
      });
    } finally {
      setLoading(false);
    }
  }, [page, keyword]);

  useEffect(() => {
    loadEmployees();
  }, [loadEmployees]);

  const handleChange = (e) => {
    const { name, value } = e.target;
    if (name === "experienceYears") {
      const parsed = value === "" ? 0 : Number(value);
      setForm({ ...form, [name]: Number.isFinite(parsed) ? parsed : 0 });
      return;
    }
    setForm({ ...form, [name]: value });
  };

  const handleSubmit = async () => {
    const payload = {
      name: (form.name || "").trim(),
      email: (form.email || "").trim(),
      role: (form.role || "").trim(),
      experienceYears: Number(form.experienceYears || 0)
    };

    if (!payload.name || !payload.role) {
      setToast({ open: true, message: "Name and Role are required.", severity: "warning" });
      return;
    }

    try {
      if (editingId) {
        await updateEmployee(editingId, payload);
        setToast({ open: true, message: "Employee updated.", severity: "success" });
      } else {
        await createEmployee(payload);
        setToast({ open: true, message: "Employee added.", severity: "success" });
      }
      setEditingId(null);
      setForm({ name: "", email: "", role: "", experienceYears: 0 });
      loadEmployees();
    } catch (err) {
      setToast({ open: true, message: "Save failed. Please re-check the form values.", severity: "error" });
    }
  };

  const handleDelete = async (id) => {
    try {
      await deleteEmployee(id);
      setToast({ open: true, message: "Employee deleted.", severity: "success" });
      loadEmployees();
    } catch (err) {
      setToast({ open: true, message: "Delete failed.", severity: "error" });
    }
  };

  const handleEdit = (emp) => {
    setForm({
      name: emp?.name ?? "",
      email: emp?.email ?? "",
      role: emp?.role ?? "",
      experienceYears: emp?.experienceYears ?? 0
    });
    setEditingId(emp.id);
  };

  const handleSearch = () => {
    setPage(0);
    const nextKeyword = (keywordInput || "").trim();
    setKeyword(nextKeyword);
    if (page === 0 && keyword === nextKeyword) {
      loadEmployees();
    }
  };

  return (
    <Container maxWidth="lg" sx={{ py: { xs: 4, md: 6 } }}>
      <Stack spacing={3}>
        <Box>
          <Typography
            variant="h3"
            sx={{
              fontWeight: 800,
              letterSpacing: "-0.03em",
              lineHeight: 1.05,
              background: "linear-gradient(90deg, #c4b5fd 0%, #67e8f9 45%, #fbcfe8 100%)",
              WebkitBackgroundClip: "text",
              WebkitTextFillColor: "transparent"
            }}
          >
            Employee Dashboard
          </Typography>
          <Typography sx={{ mt: 1, color: "rgba(255,255,255,0.72)" }}>
            Search, add, edit, and manage employees with a clean glass UI.
          </Typography>
        </Box>

        <Paper sx={{ ...glassSx, p: 2.25 }}>
          <Stack direction={{ xs: "column", sm: "row" }} spacing={2} alignItems="stretch">
            <TextField
              label="Search by name or role"
              value={keywordInput}
              onChange={(e) => setKeywordInput(e.target.value)}
              onKeyDown={(e) => {
                if (e.key === "Enter") handleSearch();
              }}
              fullWidth
              InputProps={{
                startAdornment: (
                  <InputAdornment position="start">
                    <SearchRoundedIcon />
                  </InputAdornment>
                )
              }}
            />
            <Button
              variant="contained"
              onClick={handleSearch}
              sx={{
                minWidth: 140,
                background: "linear-gradient(135deg, rgba(139,92,246,1) 0%, rgba(34,211,238,1) 100%)"
              }}
            >
              Search
            </Button>
          </Stack>
        </Paper>

        <Paper sx={{ ...glassSx, p: 2.25 }}>
          <Stack direction={{ xs: "column", md: "row" }} spacing={2} alignItems={{ md: "center" }}>
            <Box sx={{ flex: 1 }}>
              <Typography variant="h6" sx={{ fontWeight: 750 }}>
                {editingId ? "Edit employee" : "Add new employee"}
              </Typography>
              <Typography sx={{ color: "rgba(255,255,255,0.72)" }}>
                {editingId ? "Update and save changes." : "Fill the form to create an employee."}
              </Typography>
            </Box>
            {editingId ? (
              <Chip
                label={`Editing ID: ${editingId}`}
                color="secondary"
                variant="outlined"
                sx={{ alignSelf: { xs: "flex-start", md: "center" } }}
              />
            ) : null}
          </Stack>

          <Divider sx={{ my: 2, borderColor: "rgba(255,255,255,0.12)" }} />

          <Grid container spacing={2}>
            <Grid item xs={12} md={6}>
              <TextField
                fullWidth
                name="name"
                label="Name"
                value={form.name}
                onChange={handleChange}
                placeholder="e.g. Priya Sharma"
              />
            </Grid>
            <Grid item xs={12} md={6}>
              <TextField
                fullWidth
                name="email"
                label="Email"
                value={form.email}
                onChange={handleChange}
                placeholder="e.g. priya@company.com"
              />
            </Grid>
            <Grid item xs={12} md={6}>
              <TextField
                fullWidth
                name="role"
                label="Role"
                value={form.role}
                onChange={handleChange}
                placeholder="e.g. Backend Engineer"
              />
            </Grid>
            <Grid item xs={12} md={6}>
              <TextField
                fullWidth
                name="experienceYears"
                label="Experience (years)"
                type="number"
                value={form.experienceYears}
                onChange={handleChange}
                inputProps={{ min: 0, step: 1 }}
              />
            </Grid>
          </Grid>

          <Stack direction="row" spacing={1.5} sx={{ mt: 2.25 }}>
            <Button
              variant="contained"
              onClick={handleSubmit}
              sx={{
                px: 2.5,
                background: "linear-gradient(135deg, rgba(139,92,246,1) 0%, rgba(34,211,238,1) 100%)"
              }}
            >
              {editingId ? "Update" : "Add"}
            </Button>
            {editingId ? (
              <Button
                variant="outlined"
                onClick={() => {
                  setEditingId(null);
                  setForm({ name: "", email: "", role: "", experienceYears: 0 });
                }}
              >
                Cancel
              </Button>
            ) : null}
          </Stack>
        </Paper>

        <Paper sx={{ ...glassSx, p: 2.25 }}>
          <Stack direction="row" alignItems="center" justifyContent="space-between" spacing={2}>
            <Stack>
              <Typography variant="h6" sx={{ fontWeight: 750 }}>
                Employees
              </Typography>
              <Typography sx={{ color: "rgba(255,255,255,0.72)" }}>
                {loading ? "Loading…" : `${employees.length} shown on this page`}
              </Typography>
            </Stack>
            {loading ? <CircularProgress size={26} /> : null}
          </Stack>

          <Divider sx={{ my: 2, borderColor: "rgba(255,255,255,0.12)" }} />

          <Grid container spacing={2}>
            {!loading && employees.length === 0 ? (
              <Grid item xs={12}>
                <Typography sx={{ color: "rgba(255,255,255,0.72)" }}>
                  No employees found. Try a different keyword.
                </Typography>
              </Grid>
            ) : null}

            {employees.map((emp) => (
              <Grid item xs={12} md={6} key={emp.id}>
                <Card
                  sx={{
                    ...glassSx,
                    height: "100%",
                    transition: "transform 160ms ease, box-shadow 160ms ease",
                    "&:hover": { transform: "translateY(-2px)", boxShadow: "0 24px 70px rgba(0,0,0,0.45)" }
                  }}
                >
                  <CardContent>
                    <Stack direction="row" spacing={1.5} alignItems="flex-start" justifyContent="space-between">
                      <Stack direction="row" spacing={1.5} alignItems="center">
                        <Avatar
                          sx={{
                            bgcolor: "rgba(139,92,246,0.35)",
                            border: "1px solid rgba(255,255,255,0.18)"
                          }}
                        >
                          {(emp?.name?.[0] || "?").toUpperCase()}
                        </Avatar>
                        <Box>
                          <Typography sx={{ fontWeight: 800, letterSpacing: "-0.01em" }}>
                            {emp.name}
                          </Typography>
                          <Stack direction="row" spacing={1} alignItems="center" sx={{ mt: 0.5 }}>
                            <WorkRoundedIcon fontSize="small" style={{ opacity: 0.85 }} />
                            <Typography sx={{ color: "rgba(255,255,255,0.72)" }}>{emp.role}</Typography>
                          </Stack>
                        </Box>
                      </Stack>
                      <Chip
                        label={`ID ${emp.id}`}
                        size="small"
                        variant="outlined"
                        sx={{ borderColor: "rgba(255,255,255,0.16)" }}
                      />
                    </Stack>

                    <Stack spacing={1} sx={{ mt: 2 }}>
                      <Stack direction="row" spacing={1} alignItems="center">
                        <MailRoundedIcon fontSize="small" style={{ opacity: 0.85 }} />
                        <Typography sx={{ color: "rgba(255,255,255,0.72)" }}>{emp.email || "—"}</Typography>
                      </Stack>
                      <Stack direction="row" spacing={1} alignItems="center">
                        <TrendingUpRoundedIcon fontSize="small" style={{ opacity: 0.85 }} />
                        <Typography sx={{ color: "rgba(255,255,255,0.72)" }}>
                          {emp.experienceYears} years experience
                        </Typography>
                      </Stack>
                    </Stack>
                  </CardContent>

                  <CardActions sx={{ px: 2, pb: 2, pt: 0, justifyContent: "flex-end" }}>
                    <Tooltip title="Edit">
                      <IconButton onClick={() => handleEdit(emp)}>
                        <EditRoundedIcon />
                      </IconButton>
                    </Tooltip>
                    <Tooltip title="Delete">
                      <IconButton color="error" onClick={() => handleDelete(emp.id)}>
                        <DeleteRoundedIcon />
                      </IconButton>
                    </Tooltip>
                  </CardActions>
                </Card>
              </Grid>
            ))}
          </Grid>

          <Box sx={{ display: "flex", justifyContent: "center", mt: 3 }}>
            <Pagination
              count={totalPages}
              page={page + 1}
              onChange={(e, value) => setPage(value - 1)}
              color="primary"
              shape="rounded"
            />
          </Box>
        </Paper>

        <Snackbar
          open={toast.open}
          autoHideDuration={3500}
          onClose={() => setToast((t) => ({ ...t, open: false }))}
          anchorOrigin={{ vertical: "bottom", horizontal: "center" }}
        >
          <Alert
            severity={toast.severity}
            variant="filled"
            onClose={() => setToast((t) => ({ ...t, open: false }))}
            sx={{ width: "100%" }}
          >
            {toast.message}
          </Alert>
        </Snackbar>
      </Stack>
    </Container>
  );
}

export default EmployeePage;
