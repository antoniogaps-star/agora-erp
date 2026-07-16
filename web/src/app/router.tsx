import { createBrowserRouter } from "react-router-dom";

import { LoginPage } from "@/features/auth/LoginPage";
import { RegisterPage } from "@/features/auth/RegisterPage";
import { AccountingPage } from "@/features/accounting/AccountingPage";
import { CustomersPage } from "@/features/customers/CustomersPage";
import { InventoryPage } from "@/features/inventory/InventoryPage";
import { InvoicesPage } from "@/features/invoices/InvoicesPage";
import { ReportsPage } from "@/features/reports/ReportsPage";

import { AppLayout } from "./AppLayout";
import { ProtectedRoute } from "./ProtectedRoute";

export const router = createBrowserRouter([
  { path: "/login", element: <LoginPage /> },
  { path: "/register", element: <RegisterPage /> },
  {
    element: <ProtectedRoute />,
    children: [
      {
        element: <AppLayout />,
        children: [
          { path: "/", element: <InventoryPage /> },
          { path: "/customers", element: <CustomersPage /> },
          { path: "/invoices", element: <InvoicesPage /> },
          { path: "/reports", element: <ReportsPage /> },
          { path: "/accounting", element: <AccountingPage /> },
        ],
      },
    ],
  },
]);
