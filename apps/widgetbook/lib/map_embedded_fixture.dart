import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:k_design_tokens/k_design_tokens.dart';
import 'package:k_design_ui/k_design_ui.dart';
import 'package:k_design_ui/k_map.dart';
import 'package:k_design_ui/k_map_style.dart';

/// map-embedded: the list owns the boundary, the map is its first medium.
class MapEmbeddedFixture extends StatelessWidget {
  const MapEmbeddedFixture({super.key});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).extension<KDesignTokens>()!;
    return KPage(
      width: KPageWidth.form,
      children: [
        const KPageHeader(
          title: 'Eingebettete Karte',
          subtitle:
              'Die Liste besitzt die Rundung. Die Map schließt unten bündig an.',
        ),
        KList(
          title: 'Heute',
          separated: false,
          children: [
            SizedBox(
              height: t.sizeHitTarget * 4,
              child: KMap(
                embedded: true,
                interactive: false,
                showZoomControls: false,
                mapStyle: jsonEncode(createKMapStyle(tokens: t)),
                center: const KMapCenter(longitude: 13.388, latitude: 52.517),
                fitContent: true,
                fitContentPadding: EdgeInsets.all(t.spaceCardPadding),
                label: 'Karte als Teil der Heute-Liste',
                pins: const [
                  KMapPin(
                    id: 'start',
                    label: 'Start',
                    position: KMapCenter(longitude: 13.387, latitude: 52.53),
                  ),
                  KMapPin(
                    id: 'next',
                    label: 'Nächster Termin',
                    position: KMapCenter(longitude: 13.394, latitude: 52.525),
                  ),
                ],
                routes: const [
                  KMapRoute(
                    id: 'route',
                    coordinates: [
                      KMapCenter(longitude: 13.387, latitude: 52.53),
                      KMapCenter(longitude: 13.391, latitude: 52.531),
                      KMapCenter(longitude: 13.395, latitude: 52.527),
                      KMapCenter(longitude: 13.394, latitude: 52.525),
                    ],
                  ),
                ],
              ),
            ),
            const KListItem(
              mediaIcon: KIconName.calendar,
              title: 'Anna Müller',
              description: 'Haarschnitt',
              value: '09:00',
            ),
            const KListItem(
              mediaIcon: KIconName.circleCheck,
              title: 'Leon Fischer',
              description: 'Bartpflege',
              value: '10:30',
            ),
          ],
        ),
      ],
    );
  }
}
