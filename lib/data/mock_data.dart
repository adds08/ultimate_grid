import '../models/grid_models.dart';

const List<Worker> kAllWorkers = [
  Worker(id: 'w1', firstName: 'Carlos', lastName: 'Martinez', classification: 'Foreman', employeeNumber: '1041'),
  Worker(id: 'w2', firstName: 'Diego', lastName: 'Lopez', classification: 'Operator', employeeNumber: '1052'),
  Worker(id: 'w3', firstName: 'Marcus', lastName: 'Johnson', classification: 'Laborer', employeeNumber: '1063'),
  Worker(id: 'w4', firstName: 'Tyrell', lastName: 'Adams', classification: 'Carpenter', employeeNumber: '1074'),
  Worker(id: 'w5', firstName: 'Hector', lastName: 'Ramirez', classification: 'Laborer', employeeNumber: '1085'),
  Worker(id: 'w6', firstName: 'Andre', lastName: 'Williams', classification: 'Equipment Op', employeeNumber: '1096'),
  Worker(id: 'w7', firstName: 'Jose', lastName: 'Gonzalez', classification: 'Mason', employeeNumber: '1107'),
  Worker(id: 'w8', firstName: 'Brandon', lastName: 'Davis', classification: 'Laborer', employeeNumber: '1118'),
  Worker(id: 'w9', firstName: 'Luis', lastName: 'Hernandez', classification: 'Foreman', employeeNumber: '1129'),
  Worker(id: 'w10', firstName: 'Kevin', lastName: 'Thompson', classification: 'Carpenter', employeeNumber: '1130'),
  Worker(id: 'w11', firstName: 'Miguel', lastName: 'Sanchez', classification: 'Laborer', employeeNumber: '1141'),
  Worker(id: 'w12', firstName: 'Ronnie', lastName: 'Brooks', classification: 'Operator', employeeNumber: '1152'),
];

const List<CostCode> kAllCostCodes = [
  CostCode(id: 'c1', code: '02-100', name: 'Site Demolition', phaseCode: 'P1', unitOfMeasure: 'SF'),
  CostCode(id: 'c2', code: '02-200', name: 'Earthwork & Excavation', phaseCode: 'P1', unitOfMeasure: 'CY'),
  CostCode(id: 'c3', code: '02-300', name: 'Trenching & Backfill', phaseCode: 'P1', unitOfMeasure: 'LF'),
  CostCode(id: 'c4', code: '03-100', name: 'Concrete Forming', phaseCode: 'P2', unitOfMeasure: 'SF'),
  CostCode(id: 'c5', code: '03-200', name: 'Reinforcing Steel', phaseCode: 'P2', unitOfMeasure: 'TON'),
  CostCode(id: 'c6', code: '03-300', name: 'Cast-in-place Concrete', phaseCode: 'P2', unitOfMeasure: 'CY'),
  CostCode(id: 'c7', code: '04-100', name: 'Masonry — CMU Walls', phaseCode: 'P2', unitOfMeasure: 'SF'),
  CostCode(id: 'c8', code: '05-100', name: 'Structural Steel Erection', phaseCode: 'P3', unitOfMeasure: 'TON'),
  CostCode(id: 'c9', code: '06-100', name: 'Rough Carpentry', phaseCode: 'P3', unitOfMeasure: 'BF'),
  CostCode(id: 'c10', code: '07-100', name: 'Waterproofing', phaseCode: 'P3', unitOfMeasure: 'SF'),
  CostCode(id: 'c11', code: '31-100', name: 'Sitework — Grading', phaseCode: 'P1', unitOfMeasure: 'CY'),
  CostCode(id: 'c12', code: '32-100', name: 'Asphalt Paving', phaseCode: 'P4', unitOfMeasure: 'SY'),
];

const List<String> kInitialWorkerIds = ['w1', 'w2', 'w3', 'w4', 'w5', 'w6'];
const List<String> kInitialCostCodeIds = ['c2', 'c4', 'c5', 'c6', 'c8'];

Map<String, Map<String, double>> seedCells() {
  return {
    'w1': {'c2': 4, 'c4': 4},
    'w2': {'c2': 8},
    'w3': {'c4': 5, 'c5': 3},
    'w4': {'c5': 8},
    'w5': {'c4': 4, 'c6': 4.5},
    'w6': {'c6': 9},
  };
}
