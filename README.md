# GoldERP Pro - 웹 버전

한국금거래소 안성점을 위한 금은방 ERP 시스템의 웹 버전입니다.

## 주요 기능

- **대시보드** - 금시세, 통계, 스케줄, 주요 지표
- **고객 관리** - VIP 등급 관리, 기념일 추적, 고객 소개자 기록
- **주문 관리** - 4단계 진행 상황 추적 (상담 → 디자인 → 제작 → 완성)
- **재고 관리** - RFID/바코드 스캔, 실시간 재고 추적
- **판매/매출 관리** - 판매 기록, 매출 분석, 결제 관리
- **수리/리폼 관리** - 수리 요청 접수, 진행 상황 추적
- **거래처 관리** - 공급업체 정보, 거래 기록
- **세금 관리** - 매출세, 거래세 계산 및 기록
- **통합 검색** - Ctrl+K로 빠른 검색 (고객, 주문, 상품 등)
- **SMS/메시지** - 고객 문자 발송, 메시지 기록 관리
- **게시판** - 공지사항, 직원 메모
- 그 외 30개 이상의 기능

## 기술 스택

| 항목 | 기술 |
|------|------|
| **프론트엔드** | HTML5 + CSS3 + Vanilla JavaScript (순수 웹기술, 프레임워크 불필요) |
| **데이터베이스** | Supabase (PostgreSQL 기반) |
| **인증** | Supabase Auth (이메일 기반) |
| **호스팅** | Vercel (무료 정적 사이트 호스팅) |
| **실시간 기능** | Supabase Realtime WebSocket |
| **파일 저장소** | Supabase Storage |

## 시스템 요구사항

- 웹 브라우저 (Chrome, Safari, Firefox, Edge 최신 버전)
- 인터넷 연결
- Supabase 계정 (무료)
- Vercel 계정 (무료, 배포용)
- GitHub 계정 (코드 관리)

## 설치 및 배포 가이드

### 1단계: Supabase 프로젝트 설정

#### 1.1 Supabase 프로젝트 생성

1. [supabase.com](https://supabase.com)에 접속
2. "New Project" 클릭
3. 다음 정보 입력:
   - **Project Name**: `goldERP-production` (또는 원하는 이름)
   - **Database Password**: 안전한 비밀번호 설정
   - **Region**: `Asia-Pacific (ap-southeast-1)` 선택 (싱가포르)
   - 프로젝트 생성 대기 (약 1-2분)

#### 1.2 데이터베이스 스키마 생성

1. Supabase 대시보시 좌측에서 "SQL Editor" 클릭
2. "New Query" 클릭
3. `supabase-schema.sql` 파일의 전체 내용 복사 후 붙여넣기
4. "RUN" 버튼 클릭하여 테이블 생성

#### 1.3 사용자 인증 설정

1. 좌측 메뉴에서 "Authentication" 클릭
2. "Providers" 탭에서 Email 활성화 확인
3. "Settings" → "Email" 탭에서 다음 설정:
   - **Confirm email**: ON
   - **Auto Confirm users**: OFF (운영 중에는 ON으로 변경 가능)
   - **Double confirm changes**: ON

#### 1.4 API 키 복사

1. 우측 상단 "Project Settings" 클릭
2. "API" 탭 선택
3. 다음 정보 복사:
   - **Project URL**: `https://xxxxx.supabase.co`
   - **Anon Key**: `eyJ...` (공개 키)
   - **Service Role Key**: 나중에 필요할 때 (서버에서만 사용)

### 2단계: 설정 파일 수정

`supabase-config.js` 파일을 열고 다음을 수정하세요:

```javascript
const SUPABASE_URL = 'https://xxxxx.supabase.co'; // 1.4에서 복사한 URL
const SUPABASE_ANON_KEY = 'eyJ...'; // 1.4에서 복사한 Anon Key
const APP_NAME = 'GoldERP Pro';
const API_BASE_URL = 'https://xxxxx.supabase.co/rest/v1';
```

### 3단계: GitHub에 저장소 올리기

#### 3.1 로컬 저장소 초기화 (처음 한 번만)

```bash
cd GoldERP-Web
git init
git add .
git commit -m "Initial GoldERP Web commit"
git branch -M main
```

#### 3.2 GitHub 저장소 생성 및 연동

1. [github.com](https://github.com)에서 "New repository" 클릭
2. Repository name: `GoldERP-Web` (또는 원하는 이름)
3. 설명: `금은방 ERP 시스템 웹 버전`
4. **Public** 선택 (Vercel 배포에 필요)
5. "Create repository" 클릭

#### 3.3 원격 저장소 연동 및 푸시

```bash
git remote add origin https://github.com/YOUR_USERNAME/GoldERP-Web.git
git push -u origin main
```

### 4단계: Vercel에 배포

#### 4.1 Vercel 연동

1. [vercel.com](https://vercel.com)에 접속 (GitHub 계정으로 로그인)
2. "Add New..." → "Project" 클릭
3. "Import Git Repository" 섹션에서 `GoldERP-Web` 검색 및 선택
4. 다음 설정 후 "Deploy" 클릭:
   - **Project Name**: `goldERP-web`
   - **Framework**: `Other`
   - Environment Variables 추가 (선택사항):
     ```
     SUPABASE_URL=https://xxxxx.supabase.co
     SUPABASE_ANON_KEY=eyJ...
     ```

#### 4.2 배포 확인

- 배포 완료 후 `https://goldERP-web.vercel.app` (또는 설정한 URL)에서 접속 가능
- 모든 파일이 자동으로 로드되는지 확인

### 5단계: 첫 사용자 등록

#### 5.1 관리자 계정 생성

1. GoldERP 로그인 페이지에서 "회원가입" 클릭
2. 관리자 이메일과 비밀번호 입력 후 가입
3. 이메일 인증 (이메일 확인)

#### 5.2 추가 사용자 생성 (Supabase)

관리자는 Supabase 대시보드에서 직접 사용자를 추가할 수 있습니다:

1. Supabase 대시보드 → "Authentication" → "Users"
2. "Invite" 버튼 클릭
3. 직원 이메일 입력 및 초대

또는 GoldERP 관리 페이지에서 직원 계정 추가 (기능 개발 후)

## 데이터 이관

기존 HTML 데스크톱 버전의 데이터를 웹 버전으로 이관하려면:

1. `migrate.html` 페이지 열기
2. **Step 1**: "데이터 불러오기" 버튼으로 로컬 데이터 확인
3. **Step 2**: "업로드 시작" 버튼으로 Supabase에 업로드
4. **Step 3**: "검증 실행" 버튼으로 데이터 검증

백업 및 복원 기능:
- **JSON 파일로 백업**: 현재 로컬 데이터를 JSON 파일로 다운로드
- **JSON에서 복원**: 백업 파일을 선택하여 복원

## 파일 구조

```
GoldERP-Web/
├── index.html              # 메인 대시보드
├── login.html              # 로그인 페이지
├── migrate.html            # 데이터 이관 도구
├── supabase-config.js      # Supabase 설정 및 헬퍼 함수
├── supabase-schema.sql     # 데이터베이스 스키마
├── README.md               # 이 파일
├── css/
│   ├── styles.css          # 메인 스타일
│   └── theme.css           # 테마 (Gold/Dark)
├── js/
│   ├── app.js              # 앱 메인 로직
│   ├── dashboard.js        # 대시보드 기능
│   ├── customers.js        # 고객 관리
│   ├── orders.js           # 주문 관리
│   ├── inventory.js        # 재고 관리
│   ├── sales.js            # 판매 관리
│   └── utils.js            # 공통 유틸리티
└── assets/
    ├── logo.png            # GoldERP 로고
    └── favicon.ico         # 파비콘
```

## 사용 방법

### 로그인

1. 배포된 URL로 접속
2. 이메일과 비밀번호로 로그인
3. 첫 로그인 시 기본 정보 설정

### 주요 기능 사용법

#### 고객 관리
- **고객 추가**: 좌측 메뉴 → "고객" → "새 고객" 버튼
- **고객 검색**: Ctrl+K로 통합검색 활용
- **VIP 등급 설정**: 고객 상세 페이지에서 등급 선택

#### 주문 관리
- **주문 생성**: "주문" → "새 주문"
- **진행 상황 변경**: 주문 카드에서 단계 드래그 또는 클릭
- **예상 완성일**: 자동 계산 (제작 난이도에 따라)

#### 재고 관리
- **재고 입고**: "재고" → "입고" → 상품 및 수량 입력
- **바코드 스캔**: 입고/출고 시 바코드 스캐너 사용
- **재고 조회**: 상품명 또는 바코드로 검색

### 키보드 단축키

| 단축키 | 기능 |
|--------|------|
| `Ctrl+K` | 통합 검색 |
| `Ctrl+S` | 저장 |
| `Escape` | 모달/검색 닫기 |
| `Ctrl+N` | 새 항목 추가 |

## 비용 분석

### Supabase 무료 플랜

| 항목 | 한도 |
|------|------|
| **데이터베이스 용량** | 500MB |
| **파일 저장소** | 1GB |
| **API 호출** | 월 200만 건 |
| **실시간 동시 연결** | 최대 200개 |
| **Auth 사용자** | 무제한 |

**추정 월 사용량** (소규모 금은방 기준):
- 고객 관리: ~100명 × 100KB = 10MB
- 월 주문: ~2,000건 × 50KB = 100MB
- 재고: ~5,000개 × 20KB = 100MB
- 매출 데이터: ~50MB
- **합계**: ~250MB (무료 한도 내)

### Vercel 무료 플랜

- 월 100GB 대역폭
- 자동 배포
- SSL 인증서 (무료)
- CDN 제공

### 결론

**무료 플랜만으로도 충분히 사용 가능합니다.**

추후 데이터가 크게 늘어나면 Supabase Pro ($25/월) 또는 더 높은 플랜으로 업그레이드하세요.

## 트러블슈팅

### 로그인 실패

**문제**: "인증 오류" 메시지
- **해결**:
  1. `supabase-config.js`에서 URL과 Key 재확인
  2. Supabase 대시보드에서 "Authentication" → "Settings" 확인
  3. 이메일이 유효한지 확인

### 데이터 업로드 실패

**문제**: "데이터베이스 연결 오류"
- **해결**:
  1. 인터넷 연결 확인
  2. Supabase 상태 페이지 확인 (status.supabase.com)
  3. 브라우저 콘솔(F12)에서 오류 메시지 확인

### 페이지가 느리게 로드됨

**문제**: 초기 로드 시간이 오래 걸림
- **해결**:
  1. 브라우저 캐시 삭제 (Ctrl+Shift+Delete)
  2. 인터넷 속도 확인
  3. 다른 브라우저 시도

### API 호출 제한

**문제**: "Rate limit exceeded" 오류
- **해결**:
  1. 잠시 기다렸다가 재시도
  2. API 호출 최적화 (배치 처리 등)
  3. Supabase 요금제 업그레이드 고려

## 보안 권장사항

1. **비밀번호 관리**
   - 강력한 비밀번호 사용 (대소문자, 숫자, 특수문자)
   - 정기적인 비밀번호 변경
   - 팀원과 공유 금지

2. **API 키 보안**
   - Anon Key만 공개 사용
   - Service Role Key는 절대 공개 금지
   - 정기적인 키 로테이션

3. **데이터 백업**
   - 주 1회 이상 데이터 백업
   - `migrate.html`의 "JSON 파일로 백업" 활용
   - 중요 거래 내역은 별도 저장

4. **접근 제어**
   - 필요한 직원에게만 계정 제공
   - 권한 별 접근 제어 (준비 중)
   - 퇴사자 계정 즉시 삭제

## 기능 로드맵

### v1.0 (현재)
- ✓ 기본 CRUD 기능
- ✓ 로그인/인증
- ✓ 데이터 이관

### v1.1 (준비 중)
- 권한 관리 (관리자/직원)
- 거래처 관리
- 고급 검색 필터

### v1.2 (계획)
- 모바일 앱 (React Native)
- 오프라인 모드
- 동기화 기능

### v2.0 (미래)
- AI 매출 예측
- 바코드/RFID 통합
- 계좌 연동 결제

## 기여 (Contribution)

버그 리포트 또는 기능 요청:
1. GitHub Issues에 등록
2. Pull Request 제출 전 Issues에서 논의

## 라이센스

MIT License - 자유롭게 사용, 수정, 배포 가능합니다.

```
MIT License

Copyright (c) 2026 GoldERP Team

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions...
```

## 지원 및 문의

- **버그 리포트**: GitHub Issues
- **기술 지원**: support@golderp.dev
- **문서**: [wiki 페이지](https://github.com/your-username/GoldERP-Web/wiki)

## 감사의 말

이 프로젝트는 한국금거래소 안성점의 실제 운영 데이터를 기반으로 개발되었습니다.

---

**마지막 업데이트**: 2026년 3월
**버전**: 1.0.0
