import json
import random
import uuid
import datetime

def generate_data():
    days_ar = ["السبت", "الأحد", "الإثنين", "الثلاثاء", "الأربعاء", "الخميس", "الجمعة"]
    subjects = ["Gem", "المعاصر", "أخرى"]
    types = ["سنتر", "أونلاين", "أخرى"]
    
    first_names = ["أحمد", "محمد", "محمود", "عمر", "علي", "يوسف", "حسن", "حسين", "عبد الله", "مصطفى", "إبراهيم", "فاطمة", "مريم", "سارة", "نور", "ملك", "حبيبة", "شهد", "ندى", "آية", "رؤى", "زياد", "كريم", "ياسين", "سيف", "خالد", "مازن", "سالم"]
    last_names = ["السباعي", "النجار", "الحداد", "المصري", "المهندس", "السيد", "محمود", "علي", "إبراهيم", "حسن", "حسين", "كمال", "سعيد", "صالح", "علام", "منصور", "زكي", "رضوان"]

    groups = []
    students = []
    
    now = datetime.datetime.now().isoformat()
    
    for i in range(1, 16):
        g_id = str(uuid.uuid4())
        d1 = random.choice(days_ar)
        d2 = random.choice([d for d in days_ar if d != d1])
        
        days_json = json.dumps([
            {"day": d1, "time": f"{random.randint(12,20):02d}:00"},
            {"day": d2, "time": f"{random.randint(12,20):02d}:00"}
        ])
        
        groups.append({
            "id": g_id,
            "name": f"المجموعة رقم {i} - الصف {random.choice(['الأول', 'الثاني', 'الثالث'])}",
            "type": random.choice(types),
            "subject": random.choice(subjects),
            "days": days_json,
            "monthly_price": float(random.choice([150, 200, 250, 300])),
            "status": "نشطة",
            "created_at": now
        })
        
        num_students = random.randint(15, 30)
        for _ in range(num_students):
            s_id = str(uuid.uuid4())
            name = f"{random.choice(first_names)} {random.choice(last_names)}"
            phone = f"010{random.randint(10000000, 99999999)}"
            parent = f"011{random.randint(10000000, 99999999)}"
            
            students.append({
                "id": s_id,
                "name": name,
                "phone": phone,
                "parent_phone": parent,
                "level": random.randint(1, 10),
                "group_id": g_id,
                "notes": "",
                "points": random.randint(0, 50),
                "status": "نشط",
                "created_at": now
            })
            
    data = {
        "groups": groups,
        "students": students,
        "attendance": [],
        "exams": [],
        "exam_results": [],
        "payments": []
    }
    
    with open(r"C:\Users\AM\Desktop\backup_test.json", "w", encoding="utf-8") as f:
        json.dump(data, f, ensure_ascii=False, indent=2)

if __name__ == "__main__":
    generate_data()
