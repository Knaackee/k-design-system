// Review-only data shared in shape and values with the Storybook fixture.
class OverhaulCustomer {
  const OverhaulCustomer(
    this.id,
    this.name,
    this.area,
    this.address,
    this.note,
  );
  final String id, name, area, address, note;
}

class OverhaulBooking {
  const OverhaulBooking(
    this.id,
    this.customerId,
    this.date,
    this.start,
    this.end,
    this.service,
    this.price,
    this.travel,
    this.status,
    this.drive,
    this.km,
  );
  final String id, customerId, date, start, end, service, status, km;
  final num price, travel;
  final int drive;
  OverhaulCustomer get customer =>
      overhaulCustomers.firstWhere((c) => c.id == customerId);
  DateTime get startsAt => DateTime.parse('${date}T$start:00+01:00');
  DateTime get endsAt => DateTime.parse('${date}T$end:00+01:00');
  OverhaulBooking withStatus(String next, {num? revisedPrice}) =>
      OverhaulBooking(
        id,
        customerId,
        date,
        start,
        end,
        service,
        revisedPrice ?? price,
        travel,
        next,
        drive,
        km,
      );

  bool get pending => status == 'request' || status == 'quote';
  String get statusLabel => switch (status) {
    'confirmed' => 'Bestätigt',
    'request' => 'Anfrage',
    'quote' => 'Preis auf Anfrage',
    'expired' => 'Abgelaufen',
    _ => 'Abgesagt',
  };
}

String overhaulMoney(num amount) =>
    "${amount.toStringAsFixed(2).replaceAll('.', ',')} €";

const overhaulCustomers = <OverhaulCustomer>[
  OverhaulCustomer(
    'c1',
    'Lena Hoffmann',
    'Südvorstadt',
    'Karl-Liebknecht-Straße 88, 04275 Leipzig',
    'Kurze Seiten, oben länger.',
  ),
  OverhaulCustomer(
    'c2',
    'Jonas Becker',
    'Connewitz',
    'Bornaische Straße 18, 04277 Leipzig',
    '3. OG, kein Aufzug. Parken an der Straße.',
  ),
  OverhaulCustomer(
    'c3',
    'Renate Weber',
    'Gohlis',
    'Georg-Schumann-Straße 108, 04155 Leipzig',
    'Erdgeschoss links. Parken im Hof.',
  ),
  OverhaulCustomer(
    'c4',
    'Familie Öztürk',
    'Lößnig',
    'Arno-Nitzsche-Straße 4, 04277 Leipzig',
    '2. OG rechts. Parkplatz hinter dem Haus.',
  ),
  OverhaulCustomer(
    'c5',
    'Sophie Lange',
    'Plagwitz',
    'Karl-Heine-Straße 52, 04229 Leipzig',
    'Hinterhaus, 4. OG.',
  ),
  OverhaulCustomer(
    'c6',
    'Thomas Richter',
    'Reudnitz',
    'Dresdner Straße 61, 04317 Leipzig',
    'Hochparterre.',
  ),
  OverhaulCustomer(
    'c7',
    'Ingrid Kühn',
    'Zentrum-Süd',
    'Härtelstraße 9, 04107 Leipzig',
    '1. OG. Bitte vorher anrufen.',
  ),
];

const overhaulBookings = <OverhaulBooking>[
  OverhaulBooking(
    'b1',
    'c7',
    '2026-11-03',
    '08:30',
    '09:30',
    'Waschen & Schneiden',
    47,
    4.2,
    'confirmed',
    12,
    '4,8',
  ),
  OverhaulBooking(
    'b2',
    'c2',
    '2026-11-03',
    '10:40',
    '11:10',
    'Herrenschnitt',
    29,
    4.54,
    'confirmed',
    14,
    '6,1',
  ),
  OverhaulBooking(
    'b3',
    'c3',
    '2026-11-03',
    '11:45',
    '13:15',
    'Farbe · Schneiden',
    85,
    6.1,
    'confirmed',
    22,
    '9,4',
  ),
  OverhaulBooking(
    'b4',
    'c4',
    '2026-11-03',
    '14:30',
    '15:30',
    '3 × Kinderschnitt',
    66,
    5.3,
    'confirmed',
    26,
    '11,2',
  ),
  OverhaulBooking(
    'b5',
    'c6',
    '2026-11-04',
    '09:00',
    '09:30',
    'Herrenschnitt',
    29,
    6.4,
    'request',
    18,
    '7,3',
  ),
  OverhaulBooking(
    'b6',
    'c5',
    '2026-11-05',
    '15:10',
    '18:10',
    'Balayage',
    0,
    5.9,
    'quote',
    16,
    '6,2',
  ),
  OverhaulBooking(
    'b7',
    'c1',
    '2026-11-06',
    '10:00',
    '10:45',
    'Schneiden',
    38,
    3.9,
    'confirmed',
    9,
    '3,4',
  ),
  OverhaulBooking(
    'b8',
    'c5',
    '2026-10-30',
    '12:30',
    '13:35',
    'Langhaarschnitt · Pflege',
    74.9,
    4.38,
    'cancelled',
    16,
    '6,2',
  ),
];
