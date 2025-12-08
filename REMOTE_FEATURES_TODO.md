# MediCore Remote Features Implementation Checklist

## Database Tables (12 total)
| Table | Remote Support | Status |
|-------|----------------|--------|
| users | ✅ Yes | Done |
| patients | ✅ Yes | Done |
| rooms | ✅ Yes | Done |
| messages | ✅ Yes | Done |
| waiting_patients | ✅ Yes | Done |
| visits | ✅ Yes | Done |
| ordonnances | ✅ Yes | Done |
| payments | ✅ Yes | Done |
| medical_acts | ✅ Yes | Done |
| medications | ✅ Yes | Done |
| message_templates | ✅ Yes | Done |
| templates (user) | ✅ Yes | Done |

---

## 1. USERS MODULE
### Repository: `users_repository.dart`
| Method | Local | Remote | Status |
|--------|-------|--------|--------|
| `getAllUsers()` | ✅ | ✅ | Done |
| `getUserById(id)` | ✅ | ✅ | Done |
| `getUserByName(name)` | ✅ | ✅ | Done |
| `createUser()` | ✅ | ✅ | Done |
| `updateUser()` | ✅ | ✅ | Done |
| `deleteUser()` | ✅ | ✅ | Done |
| `getTemplateUsers()` | ✅ | ✅ | Done |
| `getPermanentUsers()` | ✅ | ✅ | Done |
| `getAllTemplates()` | ✅ | ✅ | Done |
| `createTemplate()` | ✅ | ✅ | Done |
| `createUserFromTemplate()` | ✅ | ✅ | Done |

---

## 2. PATIENTS MODULE
### Repository: `patients_repository.dart`
| Method | Local | Remote | Status |
|--------|-------|--------|--------|
| `watchAllPatients()` | ✅ | ✅ | Done |
| `getPatientByCode(code)` | ✅ | ✅ | Done |
| `searchPatients(query)` | ✅ | ✅ | Done |
| `createPatient()` | ✅ | ✅ | Done |
| `updatePatient()` | ✅ | ✅ | Done |
| `deletePatient()` | ✅ | ✅ | Done |
| `getPatientCount()` | ✅ | ✅ | Done |
| `importPatient()` | ✅ | ✅ | Done |

---

## 3. ROOMS MODULE
### Repository: `rooms_repository.dart`
| Method | Local | Remote | Status |
|--------|-------|--------|--------|
| `getAllRooms()` | ✅ | ✅ | Done |
| `getRoomById(id)` | ✅ | ✅ | Done |
| `createRoom()` | ✅ | ✅ | Done |
| `updateRoom()` | ✅ | ✅ | Done |
| `deleteRoom()` | ✅ | ✅ | Done |

### Repository: `nurse_preferences_repository.dart`
| Method | Local | Remote | Status |
|--------|-------|--------|--------|
| `getNurseRoomPreferences()` | ✅ | ✅ | Done |
| `saveNurseRoomPreferences()` | ✅ | ✅ | Done |
| `clearNurseRoomPreferences()` | ✅ | ✅ | Done |
| `getRoomsInUse()` | ✅ | ✅ | Done |
| `markNurseActive()` | ✅ | ✅ | Done |
| `markNurseInactive()` | ✅ | ✅ | Done |

---

## 4. MESSAGES MODULE
### Repository: `messages_repository.dart`
| Method | Local | Remote | Status |
|--------|-------|--------|--------|
| `sendMessage()` | ✅ | ✅ | Done |
| `getMessage(id)` | ✅ | ✅ | Done |
| `watchUnreadMessagesForNurse()` | ✅ | ✅ | Done |
| `watchUnreadMessagesForDoctor()` | ✅ | ✅ | Done |
| `watchMessagesForRoom()` | ✅ | ✅ | Done |
| `markAsRead()` | ✅ | ✅ | Done |
| `markAllAsReadForNurse()` | ✅ | ✅ | Done |
| `markAllAsReadForDoctor()` | ✅ | ✅ | Done |
| `getUnreadCountForNurse()` | ✅ | ✅ | Done |
| `getUnreadCountForDoctor()` | ✅ | ✅ | Done |
| `deleteMessage()` | ✅ | ✅ | Done |

### Repository: `message_templates_repository.dart`
| Method | Local | Remote | Status |
|--------|-------|--------|--------|
| `watchAllTemplates()` | ✅ | ✅ | Done |
| `createTemplate()` | ✅ | ✅ | Done |
| `updateTemplate()` | ✅ | ✅ | Done |
| `deleteTemplate()` | ✅ | ✅ | Done |

---

## 5. WAITING QUEUE MODULE
### Repository: `waiting_queue_repository.dart`
| Method | Local | Remote | Status |
|--------|-------|--------|--------|
| `addToQueue()` | ✅ | ✅ | Done |
| `addToDilatation()` | ✅ | ✅ | Done |
| `watchWaitingPatientsForRoom()` | ✅ | ✅ | Done |
| `watchUrgentPatientsForRoom()` | ✅ | ✅ | Done |
| `watchDilatationPatientsForRoom()` | ✅ | ✅ | Done |
| `watchDilatationPatientsForRooms()` | ✅ | ✅ | Done |
| `watchWaitingCountForRoom()` | ✅ | ✅ | Done |
| `watchUrgentCountForRoom()` | ✅ | ✅ | Done |
| `watchDilatationCountForRoom()` | ✅ | ✅ | Done |
| `watchTotalDilatationCount()` | ✅ | ✅ | Done |
| `toggleChecked()` | ✅ | ✅ | Done |
| `removeFromQueue()` | ✅ | ✅ | Done |
| `removeByPatientCode()` | ✅ | ✅ | Done |
| `markDilatationsAsNotified()` | ✅ | ✅ | Done |

---

## 6. VISITS MODULE
### Repository: `visits_repository.dart`
| Method | Local | Remote | Status |
|--------|-------|--------|--------|
| `getVisitsForPatient()` | ✅ | ✅ | Done |
| `getVisitCountForPatient()` | ✅ | ✅ | Done |
| `getVisitById()` | ✅ | ✅ | Done |
| `insertVisit()` | ✅ | ✅ | Done |
| `insertVisits()` | ✅ | ✅ | Done |
| `updateVisit()` | ✅ | ✅ | Done |
| `deleteVisit()` | ✅ | ✅ | Done |
| `hasVisitsForPatient()` | ✅ | ✅ | Done |
| `getTotalVisitCount()` | ✅ | ✅ | Done |
| `clearAllVisits()` | ✅ | ✅ | Done |

---

## 7. ORDONNANCES MODULE
### Repository: `ordonnances_repository.dart`
| Method | Local | Remote | Status |
|--------|-------|--------|--------|
| `getDocumentsForPatient()` | ✅ | ✅ | Done |
| `getDocumentsByCategory()` | ✅ | ✅ | Done (uses above) |
| `getDocumentCount()` | ✅ | ✅ | Done (uses getDocumentsForPatient) |
| `insertOrdonnance()` | ✅ | ✅ | Done |
| `updateOrdonnance()` | ✅ | ✅ | Done |
| `deleteOrdonnance()` | ✅ | ✅ | Done |

### Repository: `medications_repository.dart`
| Method | Local | Remote | Status |
|--------|-------|--------|--------|
| `getAllSortedByUsage()` | ✅ | ✅ | Done |
| `searchByCode()` | ✅ | ✅ | Done |
| `incrementUsage()` | ✅ | ✅ | Done |
| `setUsageCount()` | ✅ | ✅ | Done |
| `getById()` | ✅ | ✅ | Done |
| `getCount()` | ✅ | ✅ | Done |

---

## 8. PAYMENTS/COMPTABILITE MODULE
### Repository: `payments_repository.dart`
| Method | Local | Remote | Status |
|--------|-------|--------|--------|
| `watchPaymentsByUserAndDate()` | ✅ | ✅ | Done |
| `createPayment()` | ✅ | ✅ | Done |
| `updatePayment()` | ✅ | ✅ | Done |
| `deletePayment()` | ✅ | ✅ | Done |
| `deletePaymentsByPatientAndDate()` | ✅ | ✅ | Done |
| `countPaymentsByPatientAndDate()` | ✅ | ✅ | Done |
| `getPaymentById()` | ✅ | ✅ | Done |
| `getAllPaymentsByUser()` | ✅ | ✅ | Done |
| `importPayment()` | ✅ | ✅ | Done |
| `batchImportPayments()` | ✅ | ✅ | Done |
| `getMaxPaymentId()` | ✅ | ✅ | Done |

---

## 9. MEDICAL ACTS/HONORAIRES MODULE
### Repository: `medical_acts_repository.dart`
| Method | Local | Remote | Status |
|--------|-------|--------|--------|
| `watchAllMedicalActs()` | ✅ | ✅ | Done |
| `getAllMedicalActs()` | ✅ | ✅ | Done |
| `getMedicalAct(id)` | ✅ | ✅ | Done |
| `createMedicalAct()` | ✅ | ✅ | Done |
| `updateMedicalAct()` | ✅ | ✅ | Done |
| `deleteMedicalAct()` | ✅ | ✅ | Done |
| `reorderMedicalActs()` | ✅ | ✅ | Done |

---

## 10. AUTH MODULE
### Repository: `auth_repository.dart`
| Method | Local | Remote | Status |
|--------|-------|--------|--------|
| `login()` | ✅ | ✅ | Done (uses users) |
| `logout()` | ✅ | ✅ | Done (local state) |

---

## UI FEATURES (Non-data)

### Sounds & Notifications
| Feature | Status |
|---------|--------|
| Message notification sound | ✅ Done (client-side, uses remote streams) |
| Waiting patient sound | ✅ Done (client-side, uses remote streams) |
| Dilatation notification | ✅ Done (client-side, uses remote streams) |

### Printing
| Feature | Status |
|---------|--------|
| Print ordonnance | ✅ Done (client-side, data from remote) |
| Print visit summary | ✅ Done (client-side, data from remote) |
| Print payment receipt | ✅ Done (client-side, data from remote) |

### UI State
| Feature | Status |
|---------|--------|
| Room presence indicator | ✅ Done (uses remote data) |
| Active nurses display | ✅ Done (uses remote data) |
| Checked patient indicator | ✅ Done |

---

## SUMMARY

### Done (Remote Support Complete)
- ✅ Users (CRUD)
- ✅ Patients (CRUD + search)
- ✅ Rooms (CRUD)
- ✅ Messages (send, watch, delete)
- ✅ Waiting Queue (add, watch, remove)
- ✅ Visits (view history, count, hasVisits)
- ✅ Ordonnances (view documents)
- ✅ Medical Acts (list, watch stream)
- ✅ Medications (list, search)
- ✅ Payments (watchByUserAndDate stream)

### ALL DONE ✅
1. ~~**payments_repository.dart**~~ ✅ DONE (ALL methods)
2. ~~**medical_acts_repository.dart**~~ ✅ DONE (ALL methods including CRUD)
3. ~~**medications_repository.dart**~~ ✅ DONE (ALL methods)
4. ~~**visits_repository.dart**~~ ✅ DONE (ALL methods including batch import)
5. ~~**messages_repository.dart**~~ ✅ DONE (ALL methods)
6. ~~**waiting_queue_repository.dart**~~ ✅ DONE (ALL methods)
7. ~~**ordonnances_repository.dart**~~ ✅ DONE (ALL methods)
8. ~~**patients_repository.dart**~~ ✅ DONE (ALL methods including import)
9. ~~**users_repository.dart**~~ ✅ DONE (ALL methods including templates)
10. ~~**message_templates_repository.dart**~~ ✅ DONE (ALL methods)
11. ~~**nurse_preferences_repository.dart**~~ ✅ DONE (ALL methods)

---

## IMPLEMENTATION COMPLETE! 🎉

**EVERYTHING works the same on admin PC and client PCs.**
The only difference is where the database is stored (admin has it, client connects to it).
