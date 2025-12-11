한 눈에 보는 일기장 (AT A LOOK DIARY)
Team 2 — 이예린 · 김재이 · 김아리

Flutter · Firebase 기반 일기 & 감정 기록 앱

🔎 1. 프로젝트 소개

“한 눈에 보는 일기장”은 월간 달력 UI를 기반으로
사진 + 텍스트 + 감정 기록을 한눈에 확인할 수 있는 모바일 일기장 앱입니다.

Firebase 실시간 저장 구조를 활용하여
언제 어디서든 일상을 기록하고 되돌아볼 수 있는 플랫폼을 목표로 합니다.

🎯 2. 핵심 기능 (Key Features)

📅 달력 기반 일기 조회 — 날짜별 썸네일 자동 표시

📝 일기 작성 및 수정 — 사진 업로드 + 텍스트 기록

😊 감정 기록 기능 — 감정 선택 후 통계 확인 가능

🤝 커플 공유 일기 기능 — 서로의 일기 열람 가능

🔐 Firebase Auth 로그인 — 구글 로그인 포함

🏗️ 3. 시스템 아키텍처

Firebase Authentication

Firebase Realtime Database

Firebase Storage

Flutter Front-end

시각 자료는 /docs/03_Design_Architecture.pdf 참고

📚 4. 기술 스택 (Tech Stack)

Frontend

Flutter 3.x

Dart

Backend / Cloud

Firebase Authentication

Firebase Realtime Database

Firebase Storage

📂 5. 프로젝트 구조 (Project Structure)
lib/
 ├── screens/
 ├── services/
 ├── widgets/
 ├── models/
 └── main.dart


자세한 구조 설명은 /docs 문서 참고

🧪 6. 테스트

테스트 시나리오 및 결과는
/docs/04_Test_Report.pdf 에 포함되어 있습니다.

📸 7. 스크린샷 
# Splash
<img width="300" alt="splash" src="https://github.com/user-attachments/assets/d5d66fc4-824c-4783-8b8d-fa0752b785da" />
# Home
<img width="300" alt="home" src="https://github.com/user-attachments/assets/573c5e14-f343-4ddd-966d-dbf48e9c3abe" />
# [Main] 개인 일기장
<img width="300" alt="diary1" src="https://github.com/user-attachments/assets/d91035dd-2f39-4ef4-9f96-6087cef7ce75" /> <img width="300" alt="diary2" src="https://github.com/user-attachments/assets/70800f0a-244a-4526-b2e5-27d05f27df76" /> <img width="300" alt="diary3" src="https://github.com/user-attachments/assets/08cca0db-5897-4f39-9ddd-b25fdcc6a402" />
# 커플 연결
<img width="300" alt="couple1" src="https://github.com/user-attachments/assets/c1a5de8c-27b5-4c37-a489-e1bb6bbb380e" /> <img width="300" alt="couple2" src="https://github.com/user-attachments/assets/b4179d46-ede1-43cd-8b4e-b618e1aba8a3" />
# 커플 일기장 Mode
<img width="300" alt="coupleDiary1" src="https://github.com/user-attachments/assets/4cce80e2-c581-4d64-bf5f-53daa7831cb3" /> <img width="300" alt="coupleDiary2" src="https://github.com/user-attachments/assets/7a999626-8d16-4cd7-b3dc-287346c1a3cd" /> <img width="300" alt="coupleDiary3" src="https://github.com/user-attachments/assets/7f618ab7-6090-4984-8d25-1c4dcbaae1d0" />

▶️ 8. 시연 영상 (추후 업로드 예정)


👥 9. 팀원 역할 (Team Roles)
이예린 — Team Leader / Product Manager

프로젝트 기획, 요구사항 분석, 데이터 구조 설계, Firebase 연동 구조 수립,
SDLC 문서·테스트 보고서·사용자 매뉴얼 및 PPT 제작을 총괄.

김재이 — Full-Stack Developer

Firebase 기반 데이터 구조 설계 및 CRUD 구현,
Flutter UI 개발, 이미지 업로드 처리, Android 빌드 및 오류 해결을 담당.

김아리 — DocumentSupport & User Testing

 문서 보조,
앱 사용성 테스트 참여.

⚙️ 10. 실행 방법 (How to Run)

Flutter 패키지 설치:

flutter pub get


앱 실행:

flutter run


APK 빌드:

flutter build apk

📌 11. GitHub Repository

https://github.com/jkimj/at_a_look_diary

📄 12. 라이선스

MIT License
