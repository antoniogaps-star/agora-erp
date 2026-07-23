import { Link } from "react-router-dom";

/** Enlace estable a la última versión del APK (el workflow lo sube con nombre fijo). */
const APK_URL =
  "https://github.com/antoniogaps-star/agora-erp/releases/latest/download/agora-erp.apk";

/** La app descargable es solo Android; iPhone/computadora usan el panel web. */
const isIOS =
  typeof navigator !== "undefined" && /iPad|iPhone|iPod/.test(navigator.userAgent);

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

        {isIOS && (
          <p
            style={{
              background: "#1e293b",
              color: "#fde68a",
              borderRadius: "10px",
              padding: "0.6rem 0.9rem",
              maxWidth: "480px",
              margin: "0.25rem auto 0",
              fontSize: "0.9rem",
            }}
          >
            🍎 En iPhone, Ágora se usa en el navegador (la app descargable es para Android).
          </p>
        )}

        <div className="landing-cta" style={{ flexWrap: "wrap", gap: "0.6rem" }}>
          <a
            href={APK_URL}
            className="landing-btn"
            style={{
              background: isIOS ? "#334155" : "#22C55E",
              color: isIOS ? "#e2e8f0" : "#04210F",
              fontWeight: 700,
              display: "inline-flex",
              alignItems: "center",
              gap: "0.5rem",
              order: isIOS ? 2 : 1,
            }}
          >
            📲 Descargar la app (Android)
          </a>
          <Link
            to="/register"
            className="landing-btn"
            style={{
              background: isIOS ? "#22C55E" : "#2F6DF6",
              color: isIOS ? "#04210F" : "#fff",
              fontWeight: 700,
              order: isIOS ? 1 : 2,
            }}
          >
            🍎💻 Usar en el navegador (iPhone/PC)
          </Link>
        </div>
        <p className="landing-note" style={{ color: "#94a3b8" }}>
          Prueba <strong>7 días gratis</strong>, sin tarjeta. En Android, al abrir la app toca
          <strong> "Crear empresa"</strong> (si lo pide, permite instalar de orígenes
          desconocidos). En iPhone o computadora, crea tu cuenta en el navegador.
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
            📷 Escanea para descargar (Android)
          </span>
        </div>
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
          📲 Descargar (Android)
        </a>
        <Link
          to="/register"
          className="landing-btn"
          style={{ background: "#2F6DF6", color: "#fff", fontWeight: 700, marginLeft: "0.5rem" }}
        >
          🍎💻 En el navegador
        </Link>
        <p>Ágora ERP · Dictas, vendes, GANAS</p>
      </footer>
    </div>
  );
}
