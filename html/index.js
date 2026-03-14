
const dowodContainer = document.getElementById('dowod-container');
const playerSelectContainer = document.getElementById('player-select-container');
const playerList = document.getElementById('player-list');
const btnShowAll = document.getElementById('btn-show-all');
const btnCloseSelect = document.getElementById('btn-close-select');

let autoHideTimer = null;

window.addEventListener('message', function(event) {
    const data = event.data;

    switch(data.action) {
        case 'showPlayerSelect':
            showPlayerSelect(data.players);
            break;
        case 'hidePlayerSelect':
            hidePlayerSelect();
            break;
        case 'showDowod':
            showDowod(data.data, data.showTime);
            break;
        case 'hideDowod':
            hideDowod();
            break;
    }
});

function showPlayerSelect(players) {
    playerList.innerHTML = '';

    players.forEach(player => {
        const item = document.createElement('div');
        item.className = 'player-item';
        item.innerHTML = `
            <div class="player-info">
                <span class="player-name">${escapeHtml(player.name)}</span>
                <span class="player-id">ID: ${player.id}</span>
            </div>
            <span class="player-dist">${player.dist}m</span>
        `;
        item.addEventListener('click', () => {
            fetch(`https://${GetParentResourceName()}/selectPlayer`, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ targetId: player.id })
            });
        });
        playerList.appendChild(item);
    });

    playerSelectContainer.classList.remove('hidden');
}

function hidePlayerSelect() {
    playerSelectContainer.classList.add('hidden');
}

function showDowod(data, showTime) {
    document.getElementById('dowod-imie').textContent = data.imie || '—';
    document.getElementById('dowod-nazwisko').textContent = data.nazwisko || '—';
    document.getElementById('dowod-data').textContent = data.data_urodzenia || '—';
    document.getElementById('dowod-plec').textContent = data.plec || '—';
    document.getElementById('dowod-telefon').textContent = data.numer_telefonu || 'Brak';
    document.getElementById('dowod-ssn').textContent = data.ssn || '—';
    document.getElementById('dowod-praca').textContent = data.praca || 'Bezrobotny';

    dowodContainer.classList.remove('hidden');

    const card = dowodContainer.querySelector('.dowod-card');
    card.classList.remove('closing');
    card.style.animation = 'none';
    card.offsetHeight;
    card.style.animation = '';

    const timerBar = document.getElementById('dowod-timer');
    timerBar.style.transition = 'none';
    timerBar.style.width = '100%';
    timerBar.offsetHeight;
    timerBar.style.transition = `width ${showTime}ms linear`;
    timerBar.style.width = '0%';

    if (autoHideTimer) clearTimeout(autoHideTimer);
    autoHideTimer = setTimeout(() => {
        hideDowod();
        autoHideTimer = null;
    }, showTime);
}

function hideDowod() {
    if (autoHideTimer) {
        clearTimeout(autoHideTimer);
        autoHideTimer = null;
    }

    const card = dowodContainer.querySelector('.dowod-card');
    if (!card) return;
    card.classList.add('closing');

    setTimeout(() => {
        dowodContainer.classList.add('hidden');
        card.classList.remove('closing');
    }, 300);
}

btnShowAll.addEventListener('click', function() {
    fetch(`https://${GetParentResourceName()}/showToAll`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({})
    });
});

btnCloseSelect.addEventListener('click', function() {
    fetch(`https://${GetParentResourceName()}/closeDowodMenu`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({})
    });
});

document.addEventListener('keydown', function(event) {
    if (event.key === 'Escape') {
        if (!playerSelectContainer.classList.contains('hidden')) {
            fetch(`https://${GetParentResourceName()}/closeDowodMenu`, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({})
            });
        }
    }
});

function escapeHtml(text) {
    const div = document.createElement('div');
    div.textContent = text;
    return div.innerHTML;
}

function GetParentResourceName() {
    return window.GetParentResourceName ? window.GetParentResourceName() : 'Piecius_core';
}
