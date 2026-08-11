import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';

/// Singleton that holds mechanic registration form data across all 5 steps.
/// Data is persisted to shared_preferences so it survives app restarts.
/// Call [clear] on successful final submission.
///
/// Add to pubspec.yaml:
///   shared_preferences: ^2.3.2
class RegistrationDraft {
  RegistrationDraft._();
  static final RegistrationDraft instance = RegistrationDraft._();

  // ── Step 1 ──────────────────────────────────────────────────────────────
  String username        = '';
  String email           = '';
  String password        = '';
  String confirmPassword = '';

  // ── Step 2 ──────────────────────────────────────────────────────────────
  String firstName   = '';
  String middleName  = '';
  String lastName    = '';
  String suffix      = '';
  String dob         = '';   // stored as mm/dd/yyyy string
  String sex         = 'Male';
  String address     = '';
  String mobile      = '';

  // ── Step 3 ──────────────────────────────────────────────────────────────
  String idType        = '';
  String idNumber      = '';
  String idLastName    = '';
  String idGivenName   = '';
  String idMiddleName  = '';
  String maritalStatus = '';
  String placeOfBirth  = '';
  String idDob         = '';  // stored as mm/dd/yyyy string
  String idSex         = 'Male';
  String idAddress     = '';

  // ── Step 4 — file paths (empty = not picked / file no longer exists) ────
  String validIdPath    = '';
  String ncIiPath       = '';
  List<String> certPaths = [];   // optional, multiple

  // ── Step 5 — file paths ──────────────────────────────────────────────────
  String profilePhotoPath = '';
  String faceScanPath     = '';

  // ── Highest completed step (0 = none yet) ───────────────────────────────
  int highestCompletedStep = 0;

  // ── Persistence ─────────────────────────────────────────────────────────

  Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    username             = p.getString('reg_username')        ?? '';
    email                = p.getString('reg_email')           ?? '';
    password             = p.getString('reg_password')        ?? '';
    confirmPassword      = p.getString('reg_confirmPassword') ?? '';
    firstName            = p.getString('reg_firstName')   ?? '';
    middleName           = p.getString('reg_middleName')  ?? '';
    lastName             = p.getString('reg_lastName')    ?? '';
    suffix               = p.getString('reg_suffix')      ?? '';
    dob                  = p.getString('reg_dob')         ?? '';
    sex                  = p.getString('reg_sex')         ?? 'Male';
    address              = p.getString('reg_address')     ?? '';
    mobile               = p.getString('reg_mobile')      ?? '';
    idType               = p.getString('reg_idType')      ?? '';
    idNumber             = p.getString('reg_idNumber')    ?? '';
    idLastName           = p.getString('reg_idLastName')  ?? '';
    idGivenName          = p.getString('reg_idGivenName') ?? '';
    idMiddleName         = p.getString('reg_idMiddleName') ?? '';
    maritalStatus        = p.getString('reg_maritalStatus') ?? '';
    placeOfBirth         = p.getString('reg_placeOfBirth')  ?? '';
    idDob                = p.getString('reg_idDob')       ?? '';
    idSex                = p.getString('reg_idSex')       ?? 'Male';
    idAddress            = p.getString('reg_idAddress')   ?? '';
    validIdPath          = p.getString('reg_validIdPath') ?? '';
    ncIiPath             = p.getString('reg_ncIiPath')    ?? '';
    certPaths            = p.getStringList('reg_certPaths') ?? [];
    profilePhotoPath     = p.getString('reg_profilePhotoPath') ?? '';
    faceScanPath         = p.getString('reg_faceScanPath')     ?? '';
    highestCompletedStep = p.getInt('reg_highestStep') ?? 0;
  }

  Future<void> saveStep1() async {
    final p = await SharedPreferences.getInstance();
    await p.setString('reg_username',        username);
    await p.setString('reg_email',           email);
    await p.setString('reg_password',        password);
    await p.setString('reg_confirmPassword', confirmPassword);
    if (highestCompletedStep < 1) {
      highestCompletedStep = 1;
      await p.setInt('reg_highestStep', 1);
    }
  }

  Future<void> saveStep2() async {
    final p = await SharedPreferences.getInstance();
    await p.setString('reg_firstName',  firstName);
    await p.setString('reg_middleName', middleName);
    await p.setString('reg_lastName',   lastName);
    await p.setString('reg_suffix',     suffix);
    await p.setString('reg_dob',        dob);
    await p.setString('reg_sex',        sex);
    await p.setString('reg_address',    address);
    await p.setString('reg_mobile',     mobile);
    if (highestCompletedStep < 2) {
      highestCompletedStep = 2;
      await p.setInt('reg_highestStep', 2);
    }
  }

  Future<void> saveStep3() async {
    final p = await SharedPreferences.getInstance();
    await p.setString('reg_idType',        idType);
    await p.setString('reg_idNumber',      idNumber);
    await p.setString('reg_idLastName',    idLastName);
    await p.setString('reg_idGivenName',   idGivenName);
    await p.setString('reg_idMiddleName',  idMiddleName);
    await p.setString('reg_maritalStatus', maritalStatus);
    await p.setString('reg_placeOfBirth',  placeOfBirth);
    await p.setString('reg_idDob',         idDob);
    await p.setString('reg_idSex',         idSex);
    await p.setString('reg_idAddress',     idAddress);
    if (highestCompletedStep < 3) {
      highestCompletedStep = 3;
      await p.setInt('reg_highestStep', 3);
    }
  }

  /// Saves file paths for step 4 and marks it complete.
  /// Paths are stored as strings; on restore we verify the file still exists.
  Future<void> saveStep4() async {
    final p = await SharedPreferences.getInstance();
    await p.setString('reg_validIdPath', validIdPath);
    await p.setString('reg_ncIiPath',    ncIiPath);
    await p.setStringList('reg_certPaths', certPaths);
    if (highestCompletedStep < 4) {
      highestCompletedStep = 4;
      await p.setInt('reg_highestStep', 4);
    }
  }

  /// Saves file paths for step 5 and marks it complete.
  Future<void> saveStep5() async {
    final p = await SharedPreferences.getInstance();
    await p.setString('reg_profilePhotoPath', profilePhotoPath);
    await p.setString('reg_faceScanPath',     faceScanPath);
    if (highestCompletedStep < 5) {
      highestCompletedStep = 5;
      await p.setInt('reg_highestStep', 5);
    }
  }

  /// Returns a [File] if [path] is non-empty and the file still exists on
  /// disk, otherwise null. Camera/gallery files are ephemeral on some devices
  /// so we validate before restoring.
  File? resolveFile(String path) {
    if (path.isEmpty) return null;
    final f = File(path);
    return f.existsSync() ? f : null;
  }

  Future<void> clear() async {
    final p = await SharedPreferences.getInstance();
    await p.clear();
    username = email = password = confirmPassword = firstName = middleName = lastName =
        suffix = dob = address = mobile = idType = idNumber =
        idLastName = idGivenName = idMiddleName = maritalStatus =
        placeOfBirth = idDob = idAddress = validIdPath = ncIiPath =
        profilePhotoPath = faceScanPath = '';
    certPaths = [];
    sex = idSex = 'Male';
    highestCompletedStep = 0;
  }
}