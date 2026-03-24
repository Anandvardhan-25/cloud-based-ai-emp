import axios from "axios";

const API = "http://localhost:8080/employees";

export const getEmployees = (page = 0, keyword = "") =>
  axios.get(`${API}?page=${page}&size=5&keyword=${keyword}`);

export const createEmployee = (data) =>
  axios.post(API, data);

export const updateEmployee = (id, data) =>
  axios.put(`${API}/${id}`, data);

export const deleteEmployee = (id) =>
  axios.delete(`${API}/${id}`);