'use strict';
// Кэш приложения для браузера. После первого запуска всё открывается сразу и работает без интернета.
// Файл при сборке дополняется скриптом scripts/make_sw.py: в две строки ниже он подставляет «отпечаток» сборки
// и список файлов приложения. Новая сборка = новый отпечаток = новый кэш (старый удаляется).

const BUILD = '__BUILD__';
const FILES = __FILES__;
const CACHE = 'raspisanie-app-' + BUILD;

// Рисовальный движок: в Chrome/Edge нужна одна версия, в Safari (iPhone) и Firefox — другая.
const ENGINE = typeof Intl.v8BreakIterator !== 'undefined'
  ? ['canvaskit/chromium/canvaskit.js', 'canvaskit/chromium/canvaskit.wasm']
  : ['canvaskit/canvaskit.js', 'canvaskit/canvaskit.wasm'];

// Встроенная копия расписания меняется чаще самого приложения: отдаём из кэша сразу, но тихо обновляем
const SCHEDULE = /\/assets\/assets\/schedule\//;

self.addEventListener('install', (event) => {
  event.waitUntil((async () => {
    const cache = await caches.open(CACHE);
    // 'no-cache' = спросить у сайта «изменился ли файл?»; если нет, скачивать заново не нужно
    await Promise.all([...FILES, ...ENGINE].map((name) =>
      cache.add(new Request(name, { cache: 'no-cache' })).catch(() => {})));
    await self.skipWaiting();
  })());
});

self.addEventListener('activate', (event) => {
  event.waitUntil((async () => {
    for (const key of await caches.keys()) {
      if (key.startsWith('raspisanie-app-') && key !== CACHE) await caches.delete(key);
    }
    await self.clients.claim();
  })());
});

self.addEventListener('fetch', (event) => {
  const request = event.request;
  if (request.method !== 'GET') return;
  const url = new URL(request.url);
  // Только файлы самого приложения; сервер группы и расписание из интернета идут мимо кэша
  if (url.origin !== self.location.origin || !url.pathname.startsWith(new URL(self.registration.scope).pathname)) return;
  event.respondWith(answer(request, url));
});

async function answer(request, url) {
  const cache = await caches.open(CACHE);
  // ignoreSearch: адрес «app/?что-то» и «app/» — одна и та же страница
  const saved = await cache.match(request, { ignoreSearch: true });
  if (saved) {
    if (SCHEDULE.test(url.pathname)) refresh(cache, request);
    return saved;
  }
  try {
    const fresh = await fetch(request);
    if (fresh.ok && fresh.status === 200) cache.put(request, fresh.clone());
    return fresh;
  } catch (error) {
    // Нет интернета и файла нет в кэше: для страницы отдаём главную, для остального — обычная ошибка
    if (request.mode === 'navigate') {
      const home = await cache.match('index.html', { ignoreSearch: true });
      if (home) return home;
    }
    throw error;
  }
}

function refresh(cache, request) {
  fetch(request, { cache: 'no-cache' })
    .then((fresh) => { if (fresh.ok && fresh.status === 200) cache.put(request, fresh); })
    .catch(() => {});
}
