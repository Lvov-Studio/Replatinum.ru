// Generated from https://replatinum.ru/catalog/ on 2026-10-02.
// Refresh: python tools/update_catalog_navigation.py
class CatalogNode {
  final String path, title;
  final List<CatalogNode> children;
  const CatalogNode(this.path, this.title, [this.children = const []]);
}

const catalogNavigation = <String, List<CatalogNode>>{
  "smartfony": [
    CatalogNode("/catalog/smartfony/iphone/", "iPhone", [
      CatalogNode("/catalog/smartfony/iphone/iphone-duo/", "iPhone Duo"),
      CatalogNode(
          "/catalog/smartfony/iphone/iphone-18-pro-max/", "iPhone 18 Pro Max"),
      CatalogNode("/catalog/smartfony/iphone/iphone-18-pro/", "iPhone 18 Pro"),
      CatalogNode(
          "/catalog/smartfony/iphone/iphone-17-pro-max/", "iPhone 17 Pro Max"),
      CatalogNode("/catalog/smartfony/iphone/iphone-17-pro/", "iPhone 17 Pro"),
      CatalogNode("/catalog/smartfony/iphone/iphone-air/", "iPhone Air"),
      CatalogNode("/catalog/smartfony/iphone/iphone-17/", "iPhone 17"),
      CatalogNode("/catalog/smartfony/iphone/iphone-17e/", "iPhone 17e"),
      CatalogNode(
          "/catalog/smartfony/iphone/iphone_16_pro_max/", "iPhone 16 Pro Max"),
      CatalogNode("/catalog/smartfony/iphone/iphone_16_pro/", "iPhone 16 Pro"),
      CatalogNode(
          "/catalog/smartfony/iphone/iphone_16_plus/", "iPhone 16 Plus"),
      CatalogNode("/catalog/smartfony/iphone/iphone_16/", "iPhone 16"),
      CatalogNode("/catalog/smartfony/iphone/iphone_15/", "iPhone 15"),
    ]),
    CatalogNode("/catalog/smartfony/samsung/", "Samsung", [
      CatalogNode("/catalog/smartfony/samsung/galaxy_a/", "Galaxy A"),
      CatalogNode("/catalog/smartfony/samsung/galaxy_s/", "Galaxy S"),
      CatalogNode("/catalog/smartfony/samsung/galaxy-z-fold7-galaxy-z-flip7/",
          "Galaxy Z"),
    ]),
    CatalogNode("/catalog/smartfony/google_pixel/", "Google Pixel", []),
  ],
  "planshety": [
    CatalogNode("/catalog/planshety/samsungP/", "Samsung", []),
  ],
  "umnye_chasy_i_fitnes_braslety": [
    CatalogNode("/catalog/umnye_chasy_i_fitnes_braslety/garmin/", "Garmin", []),
  ],
  "mac": [
    CatalogNode("/catalog/mac/macbook-pro/", "Macbook Pro", [
      CatalogNode("/catalog/mac/macbook-pro/macbook-pro-14-2025/",
          "MacBook Pro 14 (2025)"),
      CatalogNode("/catalog/mac/macbook-pro/macbook-pro-14-2026/",
          "MacBook Pro 14 (2026)"),
      CatalogNode("/catalog/mac/macbook-pro/macbook-pro-16-2026/",
          "MacBook Pro 16 (2026)"),
    ]),
    CatalogNode("/catalog/mac/imac1/", "iMac", [
      CatalogNode("/catalog/mac/imac1/imac-2024/", "iMac (2024)"),
    ]),
    CatalogNode("/catalog/mac/mac-mini/", "Mac Mini", []),
  ],
  "dyson": [
    CatalogNode("/catalog/dyson/vypryamiteli/", "Выпрямители", [
      CatalogNode(
          "/catalog/dyson/vypryamiteli/vypryamiteli-dyson-airstrait-ht01/",
          "Выпрямители Dyson Airstrait HT01"),
    ]),
    CatalogNode("/catalog/dyson/feny/", "Фены", [
      CatalogNode("/catalog/dyson/feny/feny-dyson-supersonic-nural-hd16/",
          "Фены Dyson Supersonic Nural HD16"),
      CatalogNode("/catalog/dyson/feny/feny-dyson-supersonic-hd17-r-pro/",
          "Фены Dyson Supersonic HD17"),
      CatalogNode("/catalog/dyson/feny/feny-dyson-supersonic-hd18/",
          "Фены Dyson Supersonic HD18"),
    ]),
    CatalogNode("/catalog/dyson/pylesosy_dyson/", "Пылесосы Dyson", []),
  ],
  "naushniki_i_kolonki": [
    CatalogNode("/catalog/naushniki_i_kolonki/portativnye_kolonki/",
        "Портативные колонки", [
      CatalogNode(
          "/catalog/naushniki_i_kolonki/portativnye_kolonki/harman_kardon/",
          "Harman Kardon"),
      CatalogNode(
          "/catalog/naushniki_i_kolonki/portativnye_kolonki/jbl/", "JBL"),
      CatalogNode("/catalog/naushniki_i_kolonki/portativnye_kolonki/marshall/",
          "Marshall"),
      CatalogNode(
          "/catalog/naushniki_i_kolonki/portativnye_kolonki/yandeks_stantsii/",
          "Яндекс станции"),
    ]),
    CatalogNode("/catalog/naushniki_i_kolonki/provodnye_naushniki/",
        "Проводные наушники", []),
  ],
  "geyming": [
    CatalogNode("/catalog/geyming/igrovye_konsoli/", "Игровые консоли", [
      CatalogNode("/catalog/geyming/igrovye_konsoli/sony_playstation/",
          "Sony Playstation"),
      CatalogNode(
          "/catalog/geyming/igrovye_konsoli/microsoft_xbox/", "Microsoft Xbox"),
      CatalogNode("/catalog/geyming/igrovye_konsoli/nintendo/", "Nintendo"),
      CatalogNode("/catalog/geyming/igrovye_konsoli/valve_steam_deck/",
          "Valve Steam Deck"),
    ]),
  ],
  "umnye-gadzhety": [
    CatalogNode(
        "/catalog/umnye-gadzhety/vr_shlemy_i_ochki/", "VR шлемы и очки", []),
  ],
  "televizory_i_pristavki": [
    CatalogNode("/catalog/televizory_i_pristavki/televizory/", "Телевизоры", [
      CatalogNode(
          "/catalog/televizory_i_pristavki/televizory/televizory-hisense/",
          "Телевизоры Hisense"),
      CatalogNode(
          "/catalog/televizory_i_pristavki/televizory/televizory_samsung/",
          "Телевизоры Samsung"),
      CatalogNode("/catalog/televizory_i_pristavki/televizory/televizory-tcl/",
          "Телевизоры TCL"),
      CatalogNode(
          "/catalog/televizory_i_pristavki/televizory/televizory_xioami/",
          "Телевизоры Xioami"),
    ]),
  ],
  "aksessuary": [
    CatalogNode("/catalog/aksessuary/vneshnie_akkumulyatory/",
        "Внешние аккумуляторы", []),
    CatalogNode("/catalog/aksessuary/pitanie_i_kabeli_apple/",
        "Питание и кабели Apple", [
      CatalogNode(
          "/catalog/aksessuary/pitanie_i_kabeli_apple/adaptery_perekhodniki/",
          "Адаптеры (переходники)"),
      CatalogNode(
          "/catalog/aksessuary/pitanie_i_kabeli_apple/besprovodnye_zaryadnye_ustroystva/",
          "Беспроводные зарядные устройства"),
      CatalogNode(
          "/catalog/aksessuary/pitanie_i_kabeli_apple/kabeli/", "Кабели"),
      CatalogNode(
          "/catalog/aksessuary/pitanie_i_kabeli_apple/zaryadnye_ustroystva/",
          "Сетевые зарядные устройства"),
    ]),
    CatalogNode("/catalog/aksessuary/poiskovye_trekery_apple/",
        "Поисковые трекеры Apple", []),
    CatalogNode("/catalog/aksessuary/telepristavki/", "Телеприставки", []),
  ],
  "trendovye_igrushki": [
    CatalogNode("/catalog/trendovye_igrushki/bearbrick/", "Bearbrick", []),
  ],
};
