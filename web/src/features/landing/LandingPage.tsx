import { Link } from "react-router-dom";

/** Enlace estable a la última versión del APK (el workflow lo sube con nombre fijo). */
const APK_URL =
  "https://github.com/antoniogaps-star/agora-erp/releases/latest/download/agora-erp.apk";

/** Página pública de venta (landing). Se comparte con prospectos para su prueba gratis. */
export function LandingPage() {
  return (
    <div className="landing">
      <header className="landing-hero" style={{ background: "#000214", color: "#fff" }}>
        <img
          src="/agora-logo-mark.png"
          alt="Ágora ERP"
          style={{ width: "min(260px, 60vw)", height: "auto", margin: "0 auto 0.5rem" }}
        />
        <p className="landing-slogan" style={{ color: "#fff", marginTop: 0 }}>
          <span style={{ color: "#3AA0FF" }}>Dictas</span>,{" "}
          <span style={{ color: "#fff" }}>vendes</span>,{" "}
          <span style={{ color: "#22C55E" }}>GANAS</span>
        </p>
        <p className="landing-lead" style={{ color: "#cbd5e1" }}>
          El sistema para tu negocio que <strong>captura el inventario hablando</strong>.
          Funciona sin internet y lo controlas todo desde el celular o la computadora.
        </p>

        <div className="landing-cta">
          <a
            href={APK_URL}
            className="landing-btn"
            style={{
              background: "#22C55E",
              color: "#04210F",
              fontWeight: 700,
              display: "inline-flex",
              alignItems: "center",
              gap: "0.5rem",
            }}
          >
            📲 Descargar la app · Prueba gratis 7 días
          </a>
        </div>
        <p className="landing-note" style={{ color: "#94a3b8" }}>
          Para Android. Sin tarjeta. Al abrirla, toca <strong>"Crear empresa"</strong> y tienes
          7 días gratis. Si Android lo pide, permite instalar de orígenes desconocidos.
        </p>

        <div
          style={{
            display: "inline-flex",
            flexDirection: "column",
            alignItems: "center",
            gap: "0.4rem",
            background: "#fff",
            borderRadius: "16px",
            padding: "12px 12px 8px",
            marginTop: "0.5rem",
          }}
        >
          <img
            src="/qr-app.png"
            alt="Código QR para descargar Ágora ERP"
            style={{ width: "160px", height: "160px", display: "block" }}
          />
          <span style={{ color: "#0f172a", fontSize: "0.85rem", fontWeight: 600 }}>
            📷 Escanea para descargar
          </span>
        </div>

        <p style={{ marginTop: "0.75rem", fontSize: "0.9rem" }}>
          <Link to="/register" style={{ color: "#93c5fd" }}>
            ¿Prefieres la computadora? Usa el panel web
          </Link>
        </p>
      </header>

      <section className="landing-features">
        <article className="landing-feature">
          <span className="landing-emoji">🎤</span>
          <h3>Dictado con inteligencia artificial</h3>
          <p>Le dices "cinco cajas de 24" y la IA entiende: 120 piezas.</p>
        </article>
        <article className="landing-feature">
          <span className="landing-emoji">✈️</span>
          <h3>Funciona sin internet</h3>
          <p>Se va la señal y tu negocio sigue vendiendo. Sincroniza cuando vuelve.</p>
        </article>
        <article className="landing-feature">
          <span className="landing-emoji">📊</span>
          <h3>Reportes y caja en tu bolsillo</h3>
          <p>Mira tus ventas del día, tus más vendidos y tu saldo desde el celular.</p>
        </article>
      </section>

      <section className="landing-steps">
        <h2>Así de fácil</h2>
        <ol>
          <li><strong>Dictas</strong> tu inventario al celular.</li>
          <li><strong>Vendes</strong>, con o sin internet.</li>
          <li><strong>Ganas</strong>: controlas todo desde el panel web.</li>
        </ol>
      </section>

      <footer className="landing-foot">
        <a
          href={APK_URL}
          className="landing-btn"
          style={{ background: "#22C55E", color: "#04210F", fontWeight: 700 }}
        >
          📲 Descargar y probar gratis
        </a>
        <p>Ágora ERP · Dictas, vendes, GANAS</p>
      </footer>
    </div>
  );
}
