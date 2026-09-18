import 'package:k_design_ui/k_design_ui.dart';

typedef DataTableProject = ({
  String id,
  String title,
  String owner,
  int budget,
  String status,
  String platform,
});
const exampleProjects = <DataTableProject>[
  (
    id: 'atlas',
    title: 'Atlas website',
    owner: 'Alex Morgan',
    budget: 12000,
    status: 'active',
    platform: 'Web',
  ),
  (
    id: 'orbit',
    title: 'Orbit mobile app',
    owner: 'Jordan Lee',
    budget: 8500,
    status: 'planned',
    platform: 'Mobile',
  ),
  (
    id: 'docs',
    title: 'Design system documentation',
    owner: 'Sam Rivera',
    budget: 3200,
    status: 'active',
    platform: 'Web',
  ),
  (
    id: 'portal',
    title: 'Customer portal',
    owner: 'Alex Morgan',
    budget: 6400,
    status: 'planned',
    platform: 'Web',
  ),
  (
    id: 'audit',
    title: 'Accessibility review',
    owner: 'Sam Rivera',
    budget: 1800,
    status: 'done',
    platform: 'Web',
  ),
  (
    id: 'sync',
    title: 'Offline sync',
    owner: 'Jordan Lee',
    budget: 4200,
    status: 'active',
    platform: 'Mobile',
  ),
];
const projectStatuses = [
  KSelectOption(value: 'planned', label: 'Planned', icon: KIconName.minus),
  KSelectOption(value: 'active', label: 'In progress', icon: KIconName.clock),
  KSelectOption(value: 'done', label: 'Done', icon: KIconName.check),
];
String projectStatusLabel(String value) =>
    projectStatuses.firstWhere((option) => option.value == value).label;
