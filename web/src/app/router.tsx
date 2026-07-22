import { createBrowserRouter } from "react-router-dom";

import { LoginPage } from "@/features/auth/LoginPage";
import { RegisterPage } from "@/features/auth/RegisterPage";
import { LandingPage } from "@/features/landing/LandingPage";
import { AccountingPage } from "@/features/accounting/AccountingPage";
import { BusinessPage } from "@/features/business/BusinessPage";
import { CustomersPage } from "@/features/customers/CustomersPage";
import { DashboardPage } from "@/features/dashboard/DashboardPage";
import { ExportPage } from "@/features/export/ExportPage";
import { InventoryPage } from "@/features/inventory/InventoryPage";
import { InvoicesPage } from "@/features/invoices/InvoicesPage";
import { MovementsPage } from "@/features/movements/MovementsPage";
import { ProductsPage } from "@/features/products/ProductsPage";
import { ReportsPage } from "@/features/reports/ReportsPage";
import { UsersPage } from "@/features/users/UsersPage";

import { AppLayout } from "./AppLayout";
import { ProtectedRoute } from "./ProtectedRoute";

export const router = createBrowserRouter([
  { path: "/inicio", element: <LandingPage /> },
  { path: "/login", element: <LoginPage /> },
  { path: "/register", element: <RegisterPage /> },
  {
    element: <ProtectedRoute />,
    children: [
      {
        element: <AppLayout />,
        children: [
          { path: "/", element: <DashboardPage /> },
          { path: "/inventario", element: <InventoryPage /> },
          { path: "/productos", element: <ProductsPage /> },
          { path: "/movimientos", element: <MovementsPage /> },
          { path: "/reportes", element: <ReportsPage /> },
          { path: "/exportar", element: <ExportPage /> },
          { path: "/negocios", element: <BusinessPage /> },
          { path: "/usuarios", element: <UsersPage /> },
          // Rutas heredadas (accesibles por URL directa, fuera del menú):
          { path: "/customers", element: <CustomersPage /> },
          { path: "/invoices", element: <InvoicesPage /> },
          { path: "/accounting", element: <AccountingPage /> },
        ],
      },
    ],
  },
]);
