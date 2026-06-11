unit Finance.Strings;

interface

const
  // App-level
  APP_CAPTION = 'Учёт доходов и расходов';
  APP_STYLE_NAME = 'Glossy';
  APP_MUTEX_NAME = 'Local\FinanceApp.SingleInstance';
  APP_ALREADY_RUNNING_MSG = 'Приложение уже запущено.';

  // Shared formatting
  AMOUNT_FORMAT = '0.00';

  // Main shell
  SHELL_SIDEBAR_TITLE = 'Финансы';
  SHELL_NAV_HINT_MAIN = 'Главная';
  SHELL_NAV_HINT_ANALYTICS = 'Аналитика';
  SHELL_NAV_HINT_SETTINGS = 'Настройки';
  SHELL_BALANCE_TITLE = 'Текущий баланс:';
  SHELL_ACCOUNT_TITLE = 'Счет:';

  // Main page
  MAIN_LABEL_FILTER = 'Категория:';
  MAIN_COL_DATE = 'Дата';
  MAIN_COL_TYPE = 'Тип';
  MAIN_COL_CATEGORY = 'Категория';
  MAIN_COL_DESCRIPTION = 'Описание';
  MAIN_COL_AMOUNT = 'Сумма';
  MAIN_ICON_EDIT = '✎';
  MAIN_ICON_DELETE = '🗑';
  MAIN_BTN_ADD_TX = 'Добавить запись';
  MAIN_TX_INCOME = 'Доход';
  MAIN_TX_EXPENSE = 'Расход';
  MAIN_DELETE_CONFIRM = 'Удалить эту запись?';

  // Settings page
  SETTINGS_TITLE = 'Настройки';
  SETTINGS_BTN_EXPORT = 'Экспорт CSV';
  SETTINGS_BTN_IMPORT = 'Импорт CSV';
  SETTINGS_ACCOUNTS_TITLE = 'Счета:';
  SETTINGS_NEW_ACCOUNT_TITLE = 'Новый счет:';
  SETTINGS_BTN_ADD_ACCOUNT = 'Создать счет';
  SETTINGS_BTN_DELETE_ACCOUNT = 'Удалить счет';
  SETTINGS_ADD_ACCOUNT_FAILED =
    'Не удалось создать счет. Возможно, счет с таким именем уже существует.';
  SETTINGS_DELETE_ACCOUNT_CONFIRM_FMT =
    'Удалить счет "%s"? Будут удалены все его транзакции.';
  SETTINGS_DELETE_ACCOUNT_LAST_FORBIDDEN =
    'Нельзя удалить последний счет.';
  SETTINGS_DELETE_ACCOUNT_FAILED = 'Не удалось удалить счет.';
  SETTINGS_INCOME_CATEGORY = 'Категория доходов:';
  SETTINGS_EXPENSE_CATEGORY = 'Категория расходов:';
  SETTINGS_BTN_ADD = 'Добавить';
  SETTINGS_BTN_DELETE = 'Удалить';
  SETTINGS_DELETE_CATEGORY_CONFIRM_FMT = 'Удалить категорию "%s"?';
  SETTINGS_EXPORT_PREFIX = 'finance_export_';
  SETTINGS_EXPORT_DONE_FMT = 'Экспорт завершен: %s';
  SETTINGS_EXPORT_FILTER = 'CSV (*.csv)|*.csv';
  SETTINGS_EXPORT_FAILED_FMT = 'Не удалось экспортировать CSV: %s';
  SETTINGS_IMPORT_FILTER = 'CSV (*.csv)|*.csv|Все файлы|*.*';
  SETTINGS_IMPORT_DONE_FMT = 'Импорт завершен. Добавлено: %d, пропущено: %d';

  // Analytics page
  ANALYTICS_TITLE = 'Аналитика';
  ANALYTICS_SCOPE_TITLE = 'Режим:';
  ANALYTICS_SCOPE_ACTIVE_CAPTION = 'Активный счет';
  ANALYTICS_SCOPE_ALL_CAPTION = 'Все счета';
  ANALYTICS_TAB_OVERVIEW = 'Обзор';
  ANALYTICS_TAB_EXPENSES = 'Расходы';
  ANALYTICS_TAB_INCOME = 'Доходы';
  ANALYTICS_TAB_TRENDS = 'Тренды';
  ANALYTICS_EMPTY_DATA = 'Нет данных для выбранного счета/фильтра';
  ANALYTICS_KPI_INCOME = 'Доходы';
  ANALYTICS_KPI_EXPENSE = 'Расходы';
  ANALYTICS_KPI_BALANCE = 'Баланс';
  ANALYTICS_KPI_TX_COUNT = 'Операций';
  ANALYTICS_SERIES_INCOME = 'Доходы';
  ANALYTICS_SERIES_EXPENSE = 'Расходы';
  ANALYTICS_EMPTY_CATEGORY = '(без категории)';

  // Transaction editor
  TX_FORM_CAPTION = 'Запись';
  TX_GROUP_TYPE = 'Тип';
  TX_TYPE_INCOME = 'Доход';
  TX_TYPE_EXPENSE = 'Расход';
  TX_LABEL_DATE = 'Дата';
  TX_LABEL_SUM = 'Сумма';
  TX_LABEL_CATEGORY = 'Категория';
  TX_LABEL_DESCRIPTION = 'Описание';
  TX_BTN_CANCEL = 'Отмена';
  TX_ERR_CATEGORY_REQUIRED = 'Укажите категорию.';
  TX_ERR_AMOUNT_INVALID = 'Некорректная сумма.';
  TX_ERR_AMOUNT_POSITIVE = 'Сумма должна быть больше нуля.';

  // Repository keys and values
  REPO_KEY_ACTIVE_ACCOUNT_ID = 'active_account_id';
  REPO_KEY_ANALYTICS_SCOPE = 'analytics_scope';
  REPO_KEY_ENCODING_VERSION = 'encoding_version';
  REPO_ENCODING_VERSION = '2';
  REPO_SCOPE_ACTIVE = 'active';
  REPO_SCOPE_ALL = 'all';
  REPO_FILTER_ALL = 'Все';
  REPO_CSV_HEADER =
    'date_str,is_income,category,description,amount,account_name';
  REPO_CSV_BOOL_TRUE = '1';
  REPO_DEFAULT_ACCOUNT_NAME = 'Основной';

const
  DEFAULT_INCOME_CATEGORIES: array [0 .. 2] of string = ('Зарплата',
    'Подарок / возврат', 'Прочий доход');

  DEFAULT_EXPENSE_CATEGORIES: array [0 .. 6] of string = ('Продукты',
    'Транспорт', 'Жильё / коммунальные', 'Здоровье', 'Развлечения', 'Одежда',
    'Прочий расход');

implementation

end.
