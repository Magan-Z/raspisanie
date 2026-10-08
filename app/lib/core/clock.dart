/// «Сейчас». В приложении — настоящие часы, в тестах — подменённые.
abstract class Clock {
  DateTime now();
}

class SystemClock implements Clock {
  const SystemClock();

  @override
  DateTime now() => DateTime.now();
}

class FixedClock implements Clock {
  FixedClock(this.moment);
  DateTime moment;

  @override
  DateTime now() => moment;
}
