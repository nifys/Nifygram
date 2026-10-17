import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'config/supabase_config.dart';
import 'services/nifygram_backend.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (SupabaseConfig.isConfigured) {
    await NifygramBackend.initialize(SupabaseConfig.url, SupabaseConfig.anonKey);
  }
  runApp(const NifyGramApp());
}

class NifyGramApp extends StatefulWidget {
  const NifyGramApp({super.key});
  @override
  State<NifyGramApp> createState() => _NifyGramAppState();
}

class _NifyGramAppState extends State<NifyGramApp> {
  ThemeMode mode = ThemeMode.dark;

  void toggleTheme() => setState(() {
    mode = mode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
  });

  @override
  Widget build(BuildContext context) {
    const seed = Color(0xFF7C6CFF);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'NifyGram',
      themeMode: mode,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(seedColor: seed, brightness: Brightness.light),
        scaffoldBackgroundColor: const Color(0xFFF3F4FA),
        fontFamily: 'Roboto',
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(seedColor: seed, brightness: Brightness.dark),
        scaffoldBackgroundColor: const Color(0xFF0B0C12),
        fontFamily: 'Roboto',
      ),
      home: HomeShell(isDark: mode == ThemeMode.dark, onTheme: toggleTheme),
    );
  }
}

class HomeShell extends StatefulWidget {
  final bool isDark;
  final VoidCallback onTheme;
  const HomeShell({super.key, required this.isDark, required this.onTheme});
  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int tab = 0;
  final pages = const [ChatsPage(), GamesPage(), GiftsPage(), ProfilePage()];
  final labels = const ['Чаты', 'Игры', 'Подарки', 'Профиль'];
  final icons = const [CupertinoIcons.chat_bubble_2_fill, CupertinoIcons.gamecontroller_fill,
    CupertinoIcons.gift_fill, CupertinoIcons.person_crop_circle_fill];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      body: Stack(children: [
        const AmbientBackground(),
        SafeArea(
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 14),
              child: Row(children: [
                Container(
                  height: 42, width: 42,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15),
                    gradient: const LinearGradient(colors: [Color(0xFF9B8CFF), Color(0xFF5B50D6)]),
                    boxShadow: [BoxShadow(color: const Color(0xFF7566FF).withOpacity(.28), blurRadius: 20)],
                  ),
                  child: const Icon(CupertinoIcons.paperplane_fill, color: Colors.white, size: 21),
                ),
                const SizedBox(width: 12),
                const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('NifyGram', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: -.7)),
                  Text('Ближе, чем кажется', style: TextStyle(fontSize: 12, color: Colors.grey)),
                ])),
                GlassButton(icon: widget.isDark ? CupertinoIcons.sun_max_fill : CupertinoIcons.moon_fill, onTap: widget.onTheme),
                const SizedBox(width: 8),
                GlassButton(icon: CupertinoIcons.search, onTap: () => _toast(context, 'Поиск подключим на следующем этапе')),
              ]),
            ),
            Expanded(child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 320),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              child: KeyedSubtree(key: ValueKey(tab), child: pages[tab]),
            )),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(26),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor.withOpacity(widget.isDark ? .48 : .70),
                      border: Border.all(color: cs.outline.withOpacity(.13)),
                      borderRadius: BorderRadius.circular(26),
                    ),
                    child: Row(children: List.generate(labels.length, (i) => Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => tab = i),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 240),
                          curve: Curves.easeOutCubic,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(18),
                            color: tab == i ? cs.primary.withOpacity(.17) : Colors.transparent,
                          ),
                          child: Column(mainAxisSize: MainAxisSize.min, children: [
                            Icon(icons[i], size: 20, color: tab == i ? cs.primary : cs.onSurface.withOpacity(.58)),
                            const SizedBox(height: 4),
                            Text(labels[i], style: TextStyle(fontSize: 10, fontWeight: tab == i ? FontWeight.w700 : FontWeight.w500,
                              color: tab == i ? cs.primary : cs.onSurface.withOpacity(.62))),
                          ]),
                        ),
                      ),
                    ))),
                  ),
                ),
              ),
            ),
          ]),
        ),
      ]),
    );
  }
}

class AmbientBackground extends StatelessWidget {
  const AmbientBackground({super.key});
  @override
  Widget build(BuildContext context) => Positioned.fill(
    child: IgnorePointer(child: Stack(children: [
      Positioned(top: -100, right: -70, child: _orb(const Color(0xFF7162FF).withOpacity(.22), 260)),
      Positioned(bottom: 100, left: -100, child: _orb(const Color(0xFF27B8C7).withOpacity(.12), 240)),
    ])),
  );
  Widget _orb(Color color, double size) => Container(width: size, height: size,
    decoration: BoxDecoration(shape: BoxShape.circle, color: color,
      boxShadow: [BoxShadow(color: color, blurRadius: 90, spreadRadius: 35)]));
}

class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final VoidCallback? onTap;
  const GlassCard({super.key, required this.child, this.padding = const EdgeInsets.all(16), this.onTap});
  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(23),
    child: BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
      child: Material(
        color: Theme.of(context).cardColor.withOpacity(Theme.of(context).brightness == Brightness.dark ? .42 : .67),
        child: InkWell(onTap: onTap, child: Container(
          padding: padding,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(23),
            border: Border.all(color: Theme.of(context).colorScheme.outline.withOpacity(.12)),
          ),
          child: child,
        )),
      ),
    ),
  );
}

class GlassButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const GlassButton({super.key, required this.icon, required this.onTap});
  @override
  Widget build(BuildContext context) => Material(
    color: Theme.of(context).cardColor.withOpacity(.55),
    borderRadius: BorderRadius.circular(15),
    child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(15),
      child: Container(width: 42, height: 42,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Theme.of(context).colorScheme.outline.withOpacity(.12))),
        child: Icon(icon, size: 19))),
  );
}

class SectionTitle extends StatelessWidget {
  final String title;
  final String? trailing;
  const SectionTitle(this.title, {super.key, this.trailing});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(4, 8, 4, 13),
    child: Row(children: [Expanded(child: Text(title, style: const TextStyle(fontSize: 25, fontWeight: FontWeight.w800, letterSpacing: -.8))),
      if (trailing != null) Text(trailing!, style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w600))]),
  );
}

class ChatsPage extends StatelessWidget {
  const ChatsPage({super.key});
  final List<Map<String, String>> chats = const [
    {'name':'NifyGram', 'message':'Добро пожаловать! Здесь начинается общение.', 'time':'сейчас', 'symbol':'N'},
    {'name':'Избранное', 'message':'Сохраняйте важные сообщения и файлы', 'time':'12:40', 'symbol':'★'},
    {'name':'Игровая комната', 'message':'Мини-игры скоро появятся здесь', 'time':'вчера', 'symbol':'🎮'},
  ];
  @override
  Widget build(BuildContext context) => ListView(padding: const EdgeInsets.fromLTRB(20, 4, 20, 18), children: [
    const SectionTitle('Сообщения', trailing: 'Новый чат +'),
    GlassCard(padding: const EdgeInsets.all(15), child: Row(children: [
      const Icon(CupertinoIcons.lock_shield_fill, color: Color(0xFF8D7CFF), size: 22),
      const SizedBox(width: 12),
      const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Ваше пространство', style: TextStyle(fontWeight: FontWeight.w700)),
        SizedBox(height: 3),
        Text('Приватность — в ваших руках', style: TextStyle(fontSize: 12, color: Colors.grey)),
      ])),
      const Icon(CupertinoIcons.chevron_right, size: 16),
    ])),
    const SizedBox(height: 18),
    ...chats.map((c) => Padding(padding: const EdgeInsets.only(bottom: 10), child: GlassCard(
      padding: const EdgeInsets.all(13), onTap: () => _toast(context, 'Демо-чат. Сервер сообщений ещё не подключён.'),
      child: Row(children: [
        Container(width: 51, height: 51, decoration: const BoxDecoration(shape: BoxShape.circle,
          gradient: LinearGradient(colors: [Color(0xFF9D8CFF), Color(0xFF4E91D8)])),
          alignment: Alignment.center, child: Text(c['symbol']!, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold))),
        const SizedBox(width: 13),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(c['name']!, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
          const SizedBox(height: 5),
          Text(c['message']!, maxLines: 1, overflow: TextOverflow.ellipsis,
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(.58), fontSize: 12)),
        ])),
        Text(c['time']!, style: const TextStyle(color: Colors.grey, fontSize: 10)),
      ]),
    ))),
    const SizedBox(height: 6),
    GlassCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Всё готово к следующему этапу', style: TextStyle(fontWeight: FontWeight.w700)),
      const SizedBox(height: 7),
      Text('Подключим авторизацию, облачную синхронизацию и реальные сообщения.',
        style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(.62), height: 1.4)),
    ])),
  ]);
}

class GamesPage extends StatelessWidget {
  const GamesPage({super.key});
  @override
  Widget build(BuildContext context) => ListView(padding: const EdgeInsets.fromLTRB(20, 4, 20, 20), children: [
    const SectionTitle('Игровая зона'),
    const Text('Играйте вместе, не выходя из чата.', style: TextStyle(color: Colors.grey)),
    const SizedBox(height: 18),
    _feature(context, CupertinoIcons.gamecontroller_fill, 'Мини-игры', 'Быстрые игры с друзьями', 'В разработке'),
    _feature(context, CupertinoIcons.rocket_fill, 'Игровые боты', 'Новые сценарии прямо в чате', 'Скоро'),
    _feature(context, CupertinoIcons.star_fill, 'Достижения', 'Собирайте награды и значки', 'Скоро'),
    _feature(context, CupertinoIcons.music_note_2, 'Слушать вместе', 'Синхронное прослушивание музыки', 'Скоро'),
  ]);
}

class GiftsPage extends StatelessWidget {
  const GiftsPage({super.key});
  @override
  Widget build(BuildContext context) => ListView(padding: const EdgeInsets.fromLTRB(20, 4, 20, 20), children: [
    const SectionTitle('Подарки', trailing: 'Коллекция'),
    GlassCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(height: 145, width: double.infinity, decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [Color(0xFF292044), Color(0xFF7866DA), Color(0xFF45B8B0)])),
        child: const Center(child: Icon(CupertinoIcons.gift_fill, size: 66, color: Colors.white))),
      const SizedBox(height: 15),
      const Text('Цифровые подарки', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
      const SizedBox(height: 7),
      const Text('Коллекционные предметы, стикеры и платные темы появятся после подключения магазина.',
        style: TextStyle(color: Colors.grey, height: 1.4)),
      const SizedBox(height: 14),
      const Row(children: [Icon(CupertinoIcons.sparkles, color: Color(0xFF9D8CFF)), SizedBox(width: 8),
        Text('Nify Premium — скоро', style: TextStyle(fontWeight: FontWeight.w700))]),
    ])),
  ]);
}

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});
  @override
  Widget build(BuildContext context) => ListView(padding: const EdgeInsets.fromLTRB(20, 4, 20, 20), children: [
    const SectionTitle('Профиль'),
    GlassCard(child: Column(children: [
      Container(width: 82, height: 82, decoration: const BoxDecoration(shape: BoxShape.circle,
        gradient: LinearGradient(colors: [Color(0xFF9D8CFF), Color(0xFF4E91D8)])),
        child: const Icon(CupertinoIcons.person_fill, color: Colors.white, size: 40)),
      const SizedBox(height: 12),
      const Text('Гость NifyGram', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
      const SizedBox(height: 4),
      const Text('Аккаунт ещё не подключён', style: TextStyle(color: Colors.grey)),
      const SizedBox(height: 17),
      SizedBox(width: double.infinity, child: FilledButton(
        onPressed: () => _toast(context, 'Форма регистрации подключается на следующем этапе'),
        child: const Text('Войти или зарегистрироваться'))),
    ])),
    const SizedBox(height: 16),
    _feature(context, CupertinoIcons.lock_fill, 'Безопасность', '2FA, PIN, устройства, секретные чаты', 'Настроить'),
    _feature(context, CupertinoIcons.person_badge_plus_fill, 'Кто может связаться', 'Сообщения, звонки и приглашения', 'Настроить'),
    _feature(context, CupertinoIcons.device_phone_portrait, 'Активные устройства', 'Просмотр и завершение сессий', 'Скоро'),
    _feature(context, CupertinoIcons.paintbrush_fill, 'Внешний вид', 'Светлая и тёмная темы Liquid Glass', 'Включено'),
    _feature(context, CupertinoIcons.star_fill, 'Nify Premium', 'Платные темы и дополнительные функции', 'Скоро'),
  ]);
}

Widget _feature(BuildContext context, IconData icon, String title, String subtitle, String status) =>
  Padding(padding: const EdgeInsets.only(top: 10), child: GlassCard(
    onTap: () => _toast(context, '$title: $status'),
    child: Row(children: [
      Container(width: 44, height: 44, decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary.withOpacity(.13),
        borderRadius: BorderRadius.circular(15)), child: Icon(icon, color: Theme.of(context).colorScheme.primary)),
      const SizedBox(width: 13),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ])),
      const Icon(CupertinoIcons.chevron_right, size: 16, color: Colors.grey),
    ]),
  ));

void _toast(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text(message), behavior: SnackBarBehavior.floating,
    duration: const Duration(seconds: 2),
  ));
}
