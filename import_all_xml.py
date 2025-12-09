#!/usr/bin/env python3
"""
Import XML data into MediCore database
Deletes existing data and imports fresh from XML files
"""

import sqlite3
import xml.etree.ElementTree as ET
from datetime import datetime
import shutil
import os

# Database path
DB_PATH = "/Users/wow/Library/Containers/com.example.medicoreApp/Data/Documents/medicore.db"

# XML file paths
PAT_XML = "/Applications/eye/pat.xml"
VI_XML = "/Applications/eye/vi.xml"
OR_XML = "/Applications/eye/or.xml"
PAY_XML = "/Applications/eye/pay.xml"

def parse_date(date_str):
    """Parse DD/MM/YYYY to ISO format"""
    if not date_str or not date_str.strip():
        return None
    try:
        parts = date_str.strip().split('/')
        if len(parts) == 3:
            day, month, year = int(parts[0]), int(parts[1]), int(parts[2])
            return f"{year:04d}-{month:02d}-{day:02d}"
    except:
        pass
    return None

def parse_datetime(date_str, time_str=None):
    """Parse date and optional time to timestamp"""
    if not date_str or not date_str.strip():
        return None
    try:
        parts = date_str.strip().split('/')
        if len(parts) == 3:
            day, month, year = int(parts[0]), int(parts[1]), int(parts[2])
            hour, minute = 0, 0
            if time_str and ':' in time_str:
                time_parts = time_str.strip().split(':')
                hour = int(time_parts[0]) if time_parts[0] else 0
                minute = int(time_parts[1]) if len(time_parts) > 1 and time_parts[1] else 0
            dt = datetime(year, month, day, hour, minute)
            return int(dt.timestamp() * 1000)
    except:
        pass
    return None

def get_text(element, tag):
    """Get text from XML element"""
    el = element.find(tag)
    if el is not None and el.text:
        return el.text.strip()
    return None

def get_text_preserve(element, tag):
    """Get text preserving formatting"""
    el = element.find(tag)
    if el is not None and el.text:
        text = el.text.replace('\r\n', '\n').replace('\r', '\n').strip()
        return text if text else None
    return None

def get_int(element, tag):
    """Get integer from XML element"""
    text = get_text(element, tag)
    if text:
        try:
            return int(text)
        except:
            pass
    return None

def get_float(element, tag):
    """Get float from XML element"""
    text = get_text(element, tag)
    if text:
        try:
            return float(text)
        except:
            pass
    return None

def import_patients(conn, xml_path):
    """Import patients from XML"""
    print(f"\n📥 Importing patients from {xml_path}...")
    
    tree = ET.parse(xml_path)
    root = tree.getroot()
    records = root.findall('.//Table_Contenu')
    
    cursor = conn.cursor()
    
    # Delete existing
    cursor.execute("DELETE FROM patients")
    print(f"   Deleted existing patients")
    
    success = 0
    errors = 0
    
    for record in records:
        try:
            code = get_int(record, 'CDEP')
            if not code:
                errors += 1
                continue
            
            barcode = get_text(record, 'CODE_B')
            if not barcode or len(barcode) != 8:
                errors += 1
                continue
            
            first_name = get_text(record, 'PRP')
            last_name = get_text(record, 'NOMP')
            if not first_name or not last_name:
                errors += 1
                continue
            
            age = get_int(record, 'AGE')
            date_of_birth = parse_date(get_text(record, 'DATEN'))
            address = get_text(record, 'ADP')
            phone = get_text(record, 'TEL')
            other_info = get_text(record, 'INFOR_UTILES')
            created_at = parse_date(get_text(record, 'crée_le')) or datetime.now().strftime('%Y-%m-%d')
            
            cursor.execute("""
                INSERT INTO patients (code, barcode, created_at, first_name, last_name, 
                    age, date_of_birth, address, phone_number, other_info, updated_at, needs_sync)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 0)
            """, (code, barcode, created_at, first_name, last_name, 
                  age, date_of_birth, address, phone, other_info, created_at))
            success += 1
            
        except Exception as e:
            errors += 1
            if errors <= 5:
                print(f"   Error: {e}")
    
    conn.commit()
    print(f"   ✅ Imported {success} patients, {errors} errors")
    return success

def import_visits(conn, xml_path):
    """Import visits from XML"""
    print(f"\n📥 Importing visits from {xml_path}...")
    
    tree = ET.parse(xml_path)
    root = tree.getroot()
    records = root.findall('.//Table_Contenu')
    
    cursor = conn.cursor()
    
    # Delete existing
    cursor.execute("DELETE FROM visits")
    print(f"   Deleted existing visits")
    
    success = 0
    errors = 0
    now = datetime.now().isoformat()
    
    batch = []
    batch_size = 1000
    
    for record in records:
        try:
            patient_code = get_int(record, 'CDEP')
            if not patient_code:
                errors += 1
                continue
            
            visit_date = parse_date(get_text(record, 'DATECLI'))
            if not visit_date:
                errors += 1
                continue
            
            doctor_name = get_text(record, 'MEDCIN')
            if not doctor_name:
                errors += 1
                continue
            
            original_id = get_int(record, 'N__Enr.')
            visit_sequence = get_int(record, 'SEQC') or 1
            
            batch.append((
                original_id, patient_code, visit_sequence, visit_date, doctor_name,
                get_text(record, 'MOTIF'), get_text(record, 'DIIAG'), get_text(record, 'CAT'),
                # OD
                get_text(record, 'SCOD'), get_text(record, 'AVOD'),
                get_text(record, 'p1'), get_text(record, 'p2'), get_text(record, 'AXD'),
                get_text(record, 'VPOD'), get_text(record, 'K1_D'), get_text(record, 'K2_D'),
                get_text(record, 'R1_d'), get_text(record, 'R2_d'), get_text(record, 'RAYOND'),
                get_text(record, 'pachy1_D'), get_text(record, 'TOOD'), get_text(record, 'comentaire_D'),
                get_text(record, 'VAD'), get_text(record, 'TOOD'), get_text(record, 'LAF'), get_text(record, 'FO'),
                # OG
                get_text(record, 'SCOG'), get_text(record, 'AVOG'),
                get_text(record, 'p3'), get_text(record, 'p5'), get_text(record, 'AXG'),
                get_text(record, 'VPOG'), get_text(record, 'K1_G'), get_text(record, 'K2_G'),
                get_text(record, 'R1_G'), get_text(record, 'R2_G'), get_text(record, 'RAYONG'),
                get_text(record, 'pachy1_g'), get_text(record, 'TOOG'), get_text(record, 'commentaire_G'),
                get_text(record, 'VAG'), get_text(record, 'TOOG'), get_text(record, 'LAF_G'), get_text(record, 'FO_G'),
                # Shared
                get_text(record, 'EP'), get_text(record, 'EP'),
                now, now, 1, 1
            ))
            success += 1
            
            if len(batch) >= batch_size:
                cursor.executemany("""
                    INSERT INTO visits (original_id, patient_code, visit_sequence, visit_date, doctor_name,
                        motif, diagnosis, conduct,
                        od_sv, od_av, od_sphere, od_cylinder, od_axis, od_vl, od_k1, od_k2, od_r1, od_r2, od_r0,
                        od_pachy, od_toc, od_notes, od_gonio, od_to, od_laf, od_fo,
                        og_sv, og_av, og_sphere, og_cylinder, og_axis, og_vl, og_k1, og_k2, og_r1, og_r2, og_r0,
                        og_pachy, og_toc, og_notes, og_gonio, og_to, og_laf, og_fo,
                        addition, dip, created_at, updated_at, needs_sync, is_active)
                    VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)
                """, batch)
                conn.commit()
                batch = []
                print(f"   Progress: {success}...")
            
        except Exception as e:
            errors += 1
            if errors <= 5:
                print(f"   Error: {e}")
    
    # Insert remaining
    if batch:
        cursor.executemany("""
            INSERT INTO visits (original_id, patient_code, visit_sequence, visit_date, doctor_name,
                motif, diagnosis, conduct,
                od_sv, od_av, od_sphere, od_cylinder, od_axis, od_vl, od_k1, od_k2, od_r1, od_r2, od_r0,
                od_pachy, od_toc, od_notes, od_gonio, od_to, od_laf, od_fo,
                og_sv, og_av, og_sphere, og_cylinder, og_axis, og_vl, og_k1, og_k2, og_r1, og_r2, og_r0,
                og_pachy, og_toc, og_notes, og_gonio, og_to, og_laf, og_fo,
                addition, dip, created_at, updated_at, needs_sync, is_active)
            VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)
        """, batch)
        conn.commit()
    
    print(f"   ✅ Imported {success} visits, {errors} errors")
    return success

def import_ordonnances(conn, xml_path):
    """Import ordonnances from XML"""
    print(f"\n📥 Importing ordonnances from {xml_path}...")
    
    tree = ET.parse(xml_path)
    root = tree.getroot()
    records = root.findall('.//Table_Contenu')
    
    cursor = conn.cursor()
    
    # Delete existing
    cursor.execute("DELETE FROM ordonnances")
    print(f"   Deleted existing ordonnances")
    
    success = 0
    errors = 0
    now = datetime.now().isoformat()
    
    batch = []
    batch_size = 1000
    
    for record in records:
        try:
            patient_code = get_int(record, 'CDEP')
            if not patient_code:
                errors += 1
                continue
            
            original_id = get_int(record, 'N__Enr.')
            document_date = parse_date(get_text(record, 'DATEORD'))
            patient_age = get_int(record, 'AG2')
            sequence = get_int(record, 'SEQ') or 1
            seq_pat = get_text(record, 'SEQPAT')
            doctor_name = get_text(record, 'MEDCIN')
            amount = get_float(record, 'SMONT') or 0.0
            
            content1 = get_text_preserve(record, 'STRAIT')
            type1 = get_text(record, 'ACTEX') or 'ORDONNANCE'
            content2 = get_text_preserve(record, 'strait1')
            type2 = get_text(record, 'ACTEX1')
            content3 = get_text_preserve(record, 'strait2')
            type3 = get_text(record, 'ACTEX2')
            additional_notes = get_text_preserve(record, 'strait3')
            report_title = get_text(record, 'titre_cr')
            referred_by = get_text(record, 'ADressé_par')
            rdv_flag = get_int(record, 'rdvle') or 0
            rdv_date = get_text(record, 'datele')
            rdv_day = get_text(record, 'jourle')
            
            batch.append((
                original_id, patient_code, document_date, patient_age, sequence, seq_pat,
                doctor_name, amount, content1, type1, content2, type2, content3, type3,
                additional_notes, report_title, referred_by, rdv_flag, rdv_date, rdv_day,
                now, now
            ))
            success += 1
            
            if len(batch) >= batch_size:
                cursor.executemany("""
                    INSERT INTO ordonnances (original_id, patient_code, document_date, patient_age, sequence, seq_pat,
                        doctor_name, amount, content1, type1, content2, type2, content3, type3,
                        additional_notes, report_title, referred_by, rdv_flag, rdv_date, rdv_day,
                        created_at, updated_at)
                    VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)
                """, batch)
                conn.commit()
                batch = []
                print(f"   Progress: {success}...")
            
        except Exception as e:
            errors += 1
            if errors <= 5:
                print(f"   Error: {e}")
    
    # Insert remaining
    if batch:
        cursor.executemany("""
            INSERT INTO ordonnances (original_id, patient_code, document_date, patient_age, sequence, seq_pat,
                doctor_name, amount, content1, type1, content2, type2, content3, type3,
                additional_notes, report_title, referred_by, rdv_flag, rdv_date, rdv_day,
                created_at, updated_at)
            VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)
        """, batch)
        conn.commit()
    
    print(f"   ✅ Imported {success} ordonnances, {errors} errors")
    return success

def import_payments(conn, xml_path, patient_cache):
    """Import payments from XML"""
    print(f"\n📥 Importing payments from {xml_path}...")
    
    tree = ET.parse(xml_path)
    root = tree.getroot()
    records = root.findall('.//Table_Contenu')
    
    cursor = conn.cursor()
    
    # Delete existing
    cursor.execute("DELETE FROM payments")
    print(f"   Deleted existing payments")
    
    success = 0
    errors = 0
    now = datetime.now().isoformat()
    
    batch = []
    batch_size = 1000
    
    for record in records:
        try:
            patient_code = get_int(record, 'CDEP')
            if not patient_code:
                errors += 1
                continue
            
            id_honoraire = get_int(record, 'IDHONORAIRE') or get_int(record, 'N__Enr.')
            medical_act_id = get_int(record, 'cd_acte') or 0
            medical_act_name = get_text(record, 'ACTE') or ''
            amount = get_int(record, 'MONATNT') or 0
            user_name = get_text(record, 'MEDCIN') or ''
            
            date_str = get_text(record, 'DATE')
            time_str = get_text(record, 'HORAIR')
            payment_time = parse_datetime(date_str, time_str) or int(datetime.now().timestamp() * 1000)
            
            # Get patient name from cache
            patient_first = ''
            patient_last = ''
            if patient_code in patient_cache:
                patient_first, patient_last = patient_cache[patient_code]
            
            batch.append((
                id_honoraire, medical_act_id, medical_act_name, amount, '', user_name,
                patient_code, patient_first, patient_last, payment_time,
                payment_time, payment_time, 0, 1
            ))
            success += 1
            
            if len(batch) >= batch_size:
                cursor.executemany("""
                    INSERT INTO payments (id, medical_act_id, medical_act_name, amount, user_id, user_name,
                        patient_code, patient_first_name, patient_last_name, payment_time,
                        created_at, updated_at, needs_sync, is_active)
                    VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?)
                """, batch)
                conn.commit()
                batch = []
                print(f"   Progress: {success}...")
            
        except Exception as e:
            errors += 1
            if errors <= 5:
                print(f"   Error: {e}")
    
    # Insert remaining
    if batch:
        cursor.executemany("""
            INSERT INTO payments (id, medical_act_id, medical_act_name, amount, user_id, user_name,
                patient_code, patient_first_name, patient_last_name, payment_time,
                created_at, updated_at, needs_sync, is_active)
            VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?)
        """, batch)
        conn.commit()
    
    print(f"   ✅ Imported {success} payments, {errors} errors")
    return success

def main():
    print("=" * 60)
    print("MediCore XML Import Tool")
    print("=" * 60)
    
    # Check files exist
    for path in [PAT_XML, VI_XML, OR_XML, PAY_XML]:
        if not os.path.exists(path):
            print(f"❌ File not found: {path}")
            return
    
    # Backup database first
    backup_path = DB_PATH + ".backup_" + datetime.now().strftime("%Y%m%d_%H%M%S")
    print(f"\n📦 Creating backup: {backup_path}")
    shutil.copy2(DB_PATH, backup_path)
    
    # Connect to database
    conn = sqlite3.connect(DB_PATH)
    
    try:
        # Import patients first (needed for payments)
        patient_count = import_patients(conn, PAT_XML)
        
        # Build patient cache for payments
        cursor = conn.cursor()
        cursor.execute("SELECT code, first_name, last_name FROM patients")
        patient_cache = {row[0]: (row[1], row[2]) for row in cursor.fetchall()}
        print(f"   Built patient cache: {len(patient_cache)} entries")
        
        # Import other tables
        visit_count = import_visits(conn, VI_XML)
        ord_count = import_ordonnances(conn, OR_XML)
        pay_count = import_payments(conn, PAY_XML, patient_cache)
        
        # Final stats
        print("\n" + "=" * 60)
        print("IMPORT COMPLETE")
        print("=" * 60)
        print(f"  Patients:    {patient_count:,}")
        print(f"  Visits:      {visit_count:,}")
        print(f"  Ordonnances: {ord_count:,}")
        print(f"  Payments:    {pay_count:,}")
        print(f"\n  Backup at: {backup_path}")
        
        # Create a copy of the final database
        final_copy = "/Applications/eye/medicore_imported.db"
        shutil.copy2(DB_PATH, final_copy)
        print(f"  Final copy: {final_copy}")
        
    finally:
        conn.close()

if __name__ == "__main__":
    main()
