def apply_progress_update(entry, progress, client_updated_at):
    """Last-write-wins по клиентской метке времени (ТЗ: «При конфликте
    данных о прогрессе, полученных с разных устройств, применяется значение
    с более поздней отметкой времени сохранения»; ARCHITECTURE.md, сценарий
    «Чтение / синхронизация прогресса»). Возвращает актуальное состояние
    `entry` независимо от того, применилось ли обновление — так устройство,
    проигравшее гонку, увидит и примет более новое серверное значение,
    вместо того чтобы тихо перезаписать его устаревшими данными в следующий
    раз."""
    if entry.progress_updated_at is None or client_updated_at > entry.progress_updated_at:
        entry.progress = progress
        entry.progress_updated_at = client_updated_at
        entry.save(update_fields=["progress", "progress_updated_at"])
    return entry
