import { Link } from "react-router-dom";

/** Página pública de venta (landing). Se comparte para atraer clientes. */
export function LandingPage() {
  return (
    <div className="landing">
      <header className="landing-hero">
        <h1 className="landing-brand">Ágora ERP</h1>
        <p className="landing-slogan">Dictas. Vendes. Ganas.</p>
        <p className="landing-lead">
          El sistema para tu negocio que <strong>captura el inventario hablando</strong>.
          Funciona sin internet y lo controlas todo desde el celular o la computadora.
        </p>
        <div className="landing-cta">
          <Link to="/register" className="landing-btn landing-btn-primary">
            Pruébalo gratis
          </Link>
          <Link to="/login" className="landing-btn landing-btn-ghost">
            Ya tengo cuenta
          </Link>
        </div>
        <p className="landing-note">Sin tarjeta. Deja tu inventario capturado hoy mismo.</p>
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
          <span className="landing-emoji">👁️</span>
          <h3>Ve todo en vivo</h3>
          <p>Inventario, ventas, clientes y facturas desde donde estés.</p>
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
        <Link to="/register" className="landing-btn landing-btn-primary">
          Empieza gratis
        </Link>
        <p>Ágora ERP · Dictas. Vendes. Ganas.</p>
      </footer>
    </div>
  );
}
