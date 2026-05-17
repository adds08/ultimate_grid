import 'models.dart';

const List<Engineer> kAllEngineers = [
  Engineer(id: 'e1', firstName: 'Aarav', lastName: 'Patel', role: 'Backend Engineer', employeeNumber: '1041'),
  Engineer(id: 'e2', firstName: 'Priya', lastName: 'Sharma', role: 'Frontend Engineer', employeeNumber: '1052'),
  Engineer(id: 'e3', firstName: 'Marcus', lastName: 'Johnson', role: 'QA Engineer', employeeNumber: '1063'),
  Engineer(id: 'e4', firstName: 'Tyrell', lastName: 'Adams', role: 'DevOps Engineer', employeeNumber: '1074'),
  Engineer(id: 'e5', firstName: 'Maya', lastName: 'Iyer', role: 'Backend Engineer', employeeNumber: '1085'),
  Engineer(id: 'e6', firstName: 'Andre', lastName: 'Williams', role: 'Mobile Engineer', employeeNumber: '1096'),
  Engineer(id: 'e7', firstName: 'Jia', lastName: 'Chen', role: 'Frontend Engineer', employeeNumber: '1107'),
  Engineer(id: 'e8', firstName: 'Brandon', lastName: 'Davis', role: 'QA Engineer', employeeNumber: '1118'),
  Engineer(id: 'e9', firstName: 'Rohan', lastName: 'Mehta', role: 'Tech Lead', employeeNumber: '1129'),
  Engineer(id: 'e10', firstName: 'Kevin', lastName: 'Thompson', role: 'DevOps Engineer', employeeNumber: '1130'),
  Engineer(id: 'e11', firstName: 'Sofia', lastName: 'Reyes', role: 'Backend Engineer', employeeNumber: '1141'),
  Engineer(id: 'e12', firstName: 'Sam', lastName: 'Example', role: 'Software Engineer', employeeNumber: '1163'),
];

const List<SubTask> kAllSubTasks = [
  SubTask(id: 't1', code: 'BE-101', name: 'Auth service refactor', projectCode: 'ALPHA', unitOfMeasure: 'HRS'),
  SubTask(id: 't2', code: 'BE-102', name: 'Database migration', projectCode: 'ALPHA', unitOfMeasure: 'HRS'),
  SubTask(id: 't3', code: 'BE-103', name: 'API rate limiting', projectCode: 'ALPHA', unitOfMeasure: 'HRS'),
  SubTask(id: 't4', code: 'FE-201', name: 'Component library v2', projectCode: 'BRAVO', unitOfMeasure: 'PTS'),
  SubTask(id: 't5', code: 'FE-202', name: 'Routing migration', projectCode: 'BRAVO', unitOfMeasure: 'PTS'),
  SubTask(id: 't6', code: 'FE-203', name: 'State management refactor', projectCode: 'BRAVO', unitOfMeasure: 'PTS'),
  SubTask(id: 't7', code: 'QA-301', name: 'E2E test coverage', projectCode: 'CHARLIE', unitOfMeasure: 'HRS'),
  SubTask(id: 't8', code: 'SRE-302', name: 'Observability dashboards', projectCode: 'CHARLIE', unitOfMeasure: 'HRS'),
  SubTask(id: 't9', code: 'DEV-303', name: 'CI/CD pipeline', projectCode: 'CHARLIE', unitOfMeasure: 'HRS'),
  SubTask(id: 't10', code: 'MOB-401', name: 'iOS release prep', projectCode: 'DELTA', unitOfMeasure: 'HRS'),
  SubTask(id: 't11', code: 'MOB-402', name: 'Android release prep', projectCode: 'DELTA', unitOfMeasure: 'HRS'),
  SubTask(id: 't12', code: 'QA-403', name: 'Mobile QA suite', projectCode: 'DELTA', unitOfMeasure: 'HRS'),
];

const List<String> kInitialEngineerIds = ['e1', 'e2', 'e3', 'e4', 'e5', 'e6'];
const List<String> kInitialSubTaskIds = ['t2', 't4', 't5', 't6', 't8'];

Map<String, Map<String, double>> seedCells() {
  return {
    'e1': {'t2': 4, 't4': 4},
    'e2': {'t2': 8},
    'e3': {'t4': 5, 't5': 3},
    'e4': {'t5': 8},
    'e5': {'t4': 4, 't6': 4.5},
    'e6': {'t6': 9},
  };
}
