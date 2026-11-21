import './styles.css';
import { Game } from './core/Game.js';
import { UI } from './ui/UI.js';

const ui = new UI();
const game = new Game(ui);

(async () => {
  try {
    await game.init(document.getElementById('c'));
    const auto = new URLSearchParams(location.search).has('auto');
    ui.ready(() => game.start());
    if (auto) document.getElementById('btn-start').click();
  } catch (e) {
    console.error(e);
    ui.el.text.textContent = 'Error al iniciar: ' + (e && e.message ? e.message : e);
    ui.el.text.style.color = '#ffb4a8';
  }
})();
