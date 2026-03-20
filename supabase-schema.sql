-- ============================================================================
-- GoldERP Pro: 금은방 ERP 시스템 Supabase 스키마
-- PostgreSQL 13+ / Supabase
-- ============================================================================
-- 사용법: Supabase 대시보드 > SQL Editor에서 이 파일 전체를 붙여넣고 실행하세요.
-- 주의: RLS 정책은 테이블 생성 후 별도로 실행하셔도 됩니다.
-- ============================================================================

-- 1. 확장 및 유틸리티 함수
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- updated_at 자동 갱신 함수
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = CURRENT_TIMESTAMP;
  RETURN NEW;
END;
$$ language 'plpgsql';

-- ============================================================================
-- 2. 매장 및 사용자
-- ============================================================================

CREATE TABLE IF NOT EXISTS stores (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  owner_name TEXT,
  business_number TEXT,
  address TEXT,
  phone TEXT,
  timezone TEXT DEFAULT 'Asia/Seoul',
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);
COMMENT ON TABLE stores IS '매장 정보';

CREATE TABLE IF NOT EXISTS profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  store_id UUID NOT NULL REFERENCES stores(id) ON DELETE CASCADE,
  display_name TEXT,
  role TEXT DEFAULT 'staff' CHECK (role IN ('admin', 'staff', 'viewer')),
  phone TEXT,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);
COMMENT ON TABLE profiles IS '사용자 프로필 (Supabase Auth 연동)';

-- ============================================================================
-- 3. 상품 및 재고
-- ============================================================================

CREATE TABLE IF NOT EXISTS catalog (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  store_id UUID NOT NULL REFERENCES stores(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  category TEXT NOT NULL,
  material TEXT NOT NULL,
  price NUMERIC(15,2),
  weight NUMERIC(10,3),
  labor_cost NUMERIC(15,2),
  stone_cost NUMERIC(15,2),
  stone_weight NUMERIC(10,3),
  supplier TEXT,
  image TEXT,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);
COMMENT ON TABLE catalog IS '상품 카탈로그';

CREATE TABLE IF NOT EXISTS stones (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  store_id UUID NOT NULL REFERENCES stores(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  type TEXT NOT NULL,
  carat NUMERIC(10,2),
  grade TEXT,
  color TEXT,
  cost NUMERIC(15,2),
  company TEXT,
  status TEXT DEFAULT '재고' CHECK (status IN ('재고', '판매', '반납', '예약')),
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);
COMMENT ON TABLE stones IS '보석/돌 정보';

CREATE TABLE IF NOT EXISTS inventory (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  store_id UUID NOT NULL REFERENCES stores(id) ON DELETE CASCADE,
  model TEXT,
  name TEXT NOT NULL,
  type TEXT,
  material TEXT,
  weight NUMERIC(10,3),
  cost NUMERIC(15,2),
  barcode TEXT,
  rfid TEXT,
  status TEXT DEFAULT '재고' CHECK (status IN ('재고', '판매', '반납', '예약')),
  date TIMESTAMPTZ,
  sale_date TIMESTAMPTZ,
  return_date TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);
COMMENT ON TABLE inventory IS '상품 재고 관리';

-- ============================================================================
-- 4. 고객 관리 (소개자를 먼저 생성)
-- ============================================================================

CREATE TABLE IF NOT EXISTS introducers (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  store_id UUID NOT NULL REFERENCES stores(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  phone TEXT,
  relation TEXT,
  referral_count INTEGER DEFAULT 0,
  commission NUMERIC(15,2),
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);
COMMENT ON TABLE introducers IS '고객 소개자 정보';

CREATE TABLE IF NOT EXISTS customers (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  store_id UUID NOT NULL REFERENCES stores(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  phone TEXT,
  grade TEXT DEFAULT '일반',
  total_purchase NUMERIC(15,2) DEFAULT 0,
  last_visit DATE,
  birth DATE,
  wedding DATE,
  introducer_id UUID REFERENCES introducers(id) ON DELETE SET NULL,
  memo TEXT,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);
COMMENT ON TABLE customers IS '고객 정보';

-- ============================================================================
-- 5. 예약 및 상담
-- ============================================================================

CREATE TABLE IF NOT EXISTS bookings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  store_id UUID NOT NULL REFERENCES stores(id) ON DELETE CASCADE,
  customer_id UUID REFERENCES customers(id) ON DELETE SET NULL,
  customer_name TEXT,
  date DATE NOT NULL,
  time TIME,
  purpose TEXT,
  status TEXT DEFAULT '예약' CHECK (status IN ('예약', '확정', '완료', '취소')),
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);
COMMENT ON TABLE bookings IS '고객 예약';

CREATE TABLE IF NOT EXISTS consultations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  store_id UUID NOT NULL REFERENCES stores(id) ON DELETE CASCADE,
  customer_id UUID REFERENCES customers(id) ON DELETE SET NULL,
  customer_name TEXT,
  date TIMESTAMPTZ NOT NULL,
  staff TEXT,
  type TEXT,
  content TEXT,
  next_follow_up TEXT,
  status TEXT DEFAULT '진행중' CHECK (status IN ('진행중', '완료', '보류', '취소')),
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);
COMMENT ON TABLE consultations IS '고객 상담 기록';

-- ============================================================================
-- 6. 주문 및 판매
-- ============================================================================

CREATE TABLE IF NOT EXISTS orders (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  store_id UUID NOT NULL REFERENCES stores(id) ON DELETE CASCADE,
  order_number TEXT,
  customer_id UUID REFERENCES customers(id) ON DELETE SET NULL,
  customer_name TEXT,
  product TEXT,
  product_name TEXT,
  amount NUMERIC(15,2),
  stage TEXT DEFAULT 'A' CHECK (stage IN ('A', 'B', 'C', 'F')),
  order_date DATE,
  due_date DATE,
  visit_date DATE,
  company TEXT,
  phone TEXT,
  unpaid NUMERIC(15,2) DEFAULT 0,
  is_deleted BOOLEAN DEFAULT FALSE,
  memo TEXT,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);
COMMENT ON TABLE orders IS '주문 관리 (A:상담, B:확인중, C:진행중, F:완료)';

CREATE TABLE IF NOT EXISTS sales (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  store_id UUID NOT NULL REFERENCES stores(id) ON DELETE CASCADE,
  customer_id UUID REFERENCES customers(id) ON DELETE SET NULL,
  customer_name TEXT,
  product TEXT,
  amount NUMERIC(15,2) NOT NULL,
  payment_method TEXT,
  unpaid NUMERIC(15,2) DEFAULT 0,
  sale_date DATE NOT NULL,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);
COMMENT ON TABLE sales IS '판매 기록';

CREATE TABLE IF NOT EXISTS shipping (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  store_id UUID NOT NULL REFERENCES stores(id) ON DELETE CASCADE,
  order_id UUID REFERENCES orders(id) ON DELETE SET NULL,
  customer_name TEXT,
  method TEXT,
  tracking_number TEXT,
  address TEXT,
  status TEXT DEFAULT '준비중' CHECK (status IN ('준비중', '배송중', '배송완료', '취소')),
  ship_date DATE,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);
COMMENT ON TABLE shipping IS '주문 배송';

CREATE TABLE IF NOT EXISTS rentals (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  store_id UUID NOT NULL REFERENCES stores(id) ON DELETE CASCADE,
  customer_id UUID REFERENCES customers(id) ON DELETE SET NULL,
  customer_name TEXT,
  product_name TEXT,
  start_date DATE NOT NULL,
  end_date DATE,
  deposit NUMERIC(15,2),
  status TEXT DEFAULT '진행중' CHECK (status IN ('진행중', '완료', '연장', '취소')),
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);
COMMENT ON TABLE rentals IS '상품 대여';

-- ============================================================================
-- 7. 수리 및 AS
-- ============================================================================

CREATE TABLE IF NOT EXISTS repairs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  store_id UUID NOT NULL REFERENCES stores(id) ON DELETE CASCADE,
  repair_number TEXT,
  customer_id UUID REFERENCES customers(id) ON DELETE SET NULL,
  customer_name TEXT,
  product TEXT,
  description TEXT,
  cost NUMERIC(15,2),
  stage TEXT DEFAULT '접수' CHECK (stage IN ('접수', '진행중', '완료', '취소')),
  repair_date DATE,
  completion_date DATE,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);
COMMENT ON TABLE repairs IS '수리 기록';

-- ============================================================================
-- 8. 금 매입/매도
-- ============================================================================

CREATE TABLE IF NOT EXISTS gold_transactions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  store_id UUID NOT NULL REFERENCES stores(id) ON DELETE CASCADE,
  type TEXT NOT NULL CHECK (type IN ('금매입', '금매도')),
  weight NUMERIC(10,3),
  price_per_don NUMERIC(15,2),
  total_amount NUMERIC(15,2),
  customer_name TEXT,
  transaction_date DATE NOT NULL,
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);
COMMENT ON TABLE gold_transactions IS '금 매입/매도 거래';

-- ============================================================================
-- 9. 회계 관리
-- ============================================================================

CREATE TABLE IF NOT EXISTS taxes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  store_id UUID NOT NULL REFERENCES stores(id) ON DELETE CASCADE,
  type TEXT,
  company TEXT,
  amount NUMERIC(15,2),
  tax_date DATE,
  notes TEXT,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);
COMMENT ON TABLE taxes IS '세금 관리';

CREATE TABLE IF NOT EXISTS companies (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  store_id UUID NOT NULL REFERENCES stores(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  contact_person TEXT,
  phone TEXT,
  address TEXT,
  type TEXT,
  business_number TEXT,
  memo TEXT,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);
COMMENT ON TABLE companies IS '거래처 정보';

-- ============================================================================
-- 10. 의사소통
-- ============================================================================

CREATE TABLE IF NOT EXISTS sms_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  store_id UUID NOT NULL REFERENCES stores(id) ON DELETE CASCADE,
  recipient TEXT NOT NULL,
  message TEXT NOT NULL,
  sms_date TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  status TEXT DEFAULT '발송',
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);
COMMENT ON TABLE sms_logs IS 'SMS 발송 기록';

CREATE TABLE IF NOT EXISTS messages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  store_id UUID NOT NULL REFERENCES stores(id) ON DELETE CASCADE,
  from_user TEXT,
  to_user TEXT,
  content TEXT NOT NULL,
  is_read BOOLEAN DEFAULT FALSE,
  message_date TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);
COMMENT ON TABLE messages IS '내부 메시지';

-- ============================================================================
-- 11. 게시판 및 일정
-- ============================================================================

CREATE TABLE IF NOT EXISTS posts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  store_id UUID NOT NULL REFERENCES stores(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  author TEXT,
  content TEXT,
  view_count INTEGER DEFAULT 0,
  post_date TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);
COMMENT ON TABLE posts IS '공지사항/게시판';

CREATE TABLE IF NOT EXISTS schedules (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  store_id UUID NOT NULL REFERENCES stores(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  schedule_date DATE NOT NULL,
  schedule_time TIME,
  type TEXT,
  memo TEXT,
  assigned_to TEXT,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);
COMMENT ON TABLE schedules IS '매장 일정 관리';

-- ============================================================================
-- 12. 직원 및 기본 정보
-- ============================================================================

CREATE TABLE IF NOT EXISTS staff (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  store_id UUID NOT NULL REFERENCES stores(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  role TEXT,
  phone TEXT,
  hire_date DATE,
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);
COMMENT ON TABLE staff IS '직원 정보';

CREATE TABLE IF NOT EXISTS login_history (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  store_id UUID NOT NULL REFERENCES stores(id) ON DELETE CASCADE,
  user_email TEXT,
  login_date TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  ip_address TEXT,
  action TEXT,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);
COMMENT ON TABLE login_history IS '로그인 기록';

-- ============================================================================
-- 13. 분류 및 코드 관리
-- ============================================================================

CREATE TABLE IF NOT EXISTS code_categories (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  store_id UUID NOT NULL REFERENCES stores(id) ON DELETE CASCADE,
  category_name TEXT NOT NULL,
  code_values TEXT[] DEFAULT ARRAY[]::TEXT[],
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);
COMMENT ON TABLE code_categories IS '상품 분류 코드 관리';

CREATE TABLE IF NOT EXISTS material_codes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  store_id UUID NOT NULL REFERENCES stores(id) ON DELETE CASCADE,
  material_name TEXT NOT NULL,
  material_codes TEXT[] DEFAULT ARRAY[]::TEXT[],
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);
COMMENT ON TABLE material_codes IS '재질 코드 관리';

-- ============================================================================
-- 14. 매장 설정 테이블
-- ============================================================================

CREATE TABLE IF NOT EXISTS business_info (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  store_id UUID NOT NULL REFERENCES stores(id) ON DELETE CASCADE,
  name TEXT,
  owner TEXT,
  biz_no TEXT,
  address TEXT,
  phone TEXT,
  created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);
COMMENT ON TABLE business_info IS '사업자 정보';

-- ============================================================================
-- 15. 인덱스 생성 (성능 최적화)
-- ============================================================================

CREATE INDEX IF NOT EXISTS idx_profiles_store ON profiles(store_id);
CREATE INDEX IF NOT EXISTS idx_catalog_store ON catalog(store_id);
CREATE INDEX IF NOT EXISTS idx_catalog_category ON catalog(category);
CREATE INDEX IF NOT EXISTS idx_stones_store ON stones(store_id);
CREATE INDEX IF NOT EXISTS idx_inventory_store ON inventory(store_id);
CREATE INDEX IF NOT EXISTS idx_inventory_barcode ON inventory(barcode);
CREATE INDEX IF NOT EXISTS idx_inventory_rfid ON inventory(rfid);
CREATE INDEX IF NOT EXISTS idx_customers_store ON customers(store_id);
CREATE INDEX IF NOT EXISTS idx_customers_phone ON customers(phone);
CREATE INDEX IF NOT EXISTS idx_introducers_store ON introducers(store_id);
CREATE INDEX IF NOT EXISTS idx_bookings_store ON bookings(store_id);
CREATE INDEX IF NOT EXISTS idx_bookings_date ON bookings(date);
CREATE INDEX IF NOT EXISTS idx_consultations_store ON consultations(store_id);
CREATE INDEX IF NOT EXISTS idx_orders_store ON orders(store_id);
CREATE INDEX IF NOT EXISTS idx_orders_date ON orders(order_date);
CREATE INDEX IF NOT EXISTS idx_sales_store ON sales(store_id);
CREATE INDEX IF NOT EXISTS idx_sales_date ON sales(sale_date);
CREATE INDEX IF NOT EXISTS idx_shipping_store ON shipping(store_id);
CREATE INDEX IF NOT EXISTS idx_rentals_store ON rentals(store_id);
CREATE INDEX IF NOT EXISTS idx_repairs_store ON repairs(store_id);
CREATE INDEX IF NOT EXISTS idx_gold_tx_store ON gold_transactions(store_id);
CREATE INDEX IF NOT EXISTS idx_taxes_store ON taxes(store_id);
CREATE INDEX IF NOT EXISTS idx_companies_store ON companies(store_id);
CREATE INDEX IF NOT EXISTS idx_sms_store ON sms_logs(store_id);
CREATE INDEX IF NOT EXISTS idx_messages_store ON messages(store_id);
CREATE INDEX IF NOT EXISTS idx_posts_store ON posts(store_id);
CREATE INDEX IF NOT EXISTS idx_schedules_store ON schedules(store_id);
CREATE INDEX IF NOT EXISTS idx_staff_store ON staff(store_id);
CREATE INDEX IF NOT EXISTS idx_login_store ON login_history(store_id);

-- ============================================================================
-- 16. 트리거 (updated_at 자동 갱신)
-- ============================================================================

CREATE TRIGGER trg_stores_updated BEFORE UPDATE ON stores
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER trg_profiles_updated BEFORE UPDATE ON profiles
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER trg_catalog_updated BEFORE UPDATE ON catalog
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER trg_stones_updated BEFORE UPDATE ON stones
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER trg_inventory_updated BEFORE UPDATE ON inventory
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER trg_customers_updated BEFORE UPDATE ON customers
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER trg_introducers_updated BEFORE UPDATE ON introducers
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER trg_bookings_updated BEFORE UPDATE ON bookings
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER trg_consultations_updated BEFORE UPDATE ON consultations
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER trg_orders_updated BEFORE UPDATE ON orders
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER trg_sales_updated BEFORE UPDATE ON sales
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER trg_shipping_updated BEFORE UPDATE ON shipping
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER trg_rentals_updated BEFORE UPDATE ON rentals
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER trg_repairs_updated BEFORE UPDATE ON repairs
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER trg_gold_tx_updated BEFORE UPDATE ON gold_transactions
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER trg_taxes_updated BEFORE UPDATE ON taxes
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER trg_companies_updated BEFORE UPDATE ON companies
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER trg_posts_updated BEFORE UPDATE ON posts
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER trg_schedules_updated BEFORE UPDATE ON schedules
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER trg_staff_updated BEFORE UPDATE ON staff
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER trg_business_updated BEFORE UPDATE ON business_info
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- 17. RLS (Row Level Security) 활성화
-- ============================================================================

ALTER TABLE stores ENABLE ROW LEVEL SECURITY;
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE catalog ENABLE ROW LEVEL SECURITY;
ALTER TABLE stones ENABLE ROW LEVEL SECURITY;
ALTER TABLE inventory ENABLE ROW LEVEL SECURITY;
ALTER TABLE customers ENABLE ROW LEVEL SECURITY;
ALTER TABLE introducers ENABLE ROW LEVEL SECURITY;
ALTER TABLE bookings ENABLE ROW LEVEL SECURITY;
ALTER TABLE consultations ENABLE ROW LEVEL SECURITY;
ALTER TABLE orders ENABLE ROW LEVEL SECURITY;
ALTER TABLE sales ENABLE ROW LEVEL SECURITY;
ALTER TABLE shipping ENABLE ROW LEVEL SECURITY;
ALTER TABLE rentals ENABLE ROW LEVEL SECURITY;
ALTER TABLE repairs ENABLE ROW LEVEL SECURITY;
ALTER TABLE gold_transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE taxes ENABLE ROW LEVEL SECURITY;
ALTER TABLE companies ENABLE ROW LEVEL SECURITY;
ALTER TABLE sms_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE posts ENABLE ROW LEVEL SECURITY;
ALTER TABLE schedules ENABLE ROW LEVEL SECURITY;
ALTER TABLE staff ENABLE ROW LEVEL SECURITY;
ALTER TABLE login_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE code_categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE material_codes ENABLE ROW LEVEL SECURITY;
ALTER TABLE business_info ENABLE ROW LEVEL SECURITY;

-- ============================================================================
-- 18. RLS 정책 (같은 매장 소속만 접근 가능)
-- ============================================================================

-- 매장별 접근 정책을 간편하게 적용하기 위한 헬퍼 함수
CREATE OR REPLACE FUNCTION get_my_store_id()
RETURNS UUID AS $$
  SELECT store_id FROM profiles WHERE id = auth.uid() LIMIT 1;
$$ LANGUAGE sql SECURITY DEFINER STABLE;

-- stores: 자신이 속한 매장만 조회
CREATE POLICY "stores_select" ON stores FOR SELECT
  USING (id = get_my_store_id());

-- profiles: 같은 매장 프로필 조회/수정
CREATE POLICY "profiles_select" ON profiles FOR SELECT
  USING (store_id = get_my_store_id());
CREATE POLICY "profiles_update" ON profiles FOR UPDATE
  USING (id = auth.uid());
CREATE POLICY "profiles_insert" ON profiles FOR INSERT
  WITH CHECK (id = auth.uid());

-- 나머지 테이블: 같은 매장 CRUD (반복 패턴)
-- catalog
CREATE POLICY "catalog_select" ON catalog FOR SELECT USING (store_id = get_my_store_id());
CREATE POLICY "catalog_insert" ON catalog FOR INSERT WITH CHECK (store_id = get_my_store_id());
CREATE POLICY "catalog_update" ON catalog FOR UPDATE USING (store_id = get_my_store_id());
CREATE POLICY "catalog_delete" ON catalog FOR DELETE USING (store_id = get_my_store_id());

-- stones
CREATE POLICY "stones_select" ON stones FOR SELECT USING (store_id = get_my_store_id());
CREATE POLICY "stones_insert" ON stones FOR INSERT WITH CHECK (store_id = get_my_store_id());
CREATE POLICY "stones_update" ON stones FOR UPDATE USING (store_id = get_my_store_id());
CREATE POLICY "stones_delete" ON stones FOR DELETE USING (store_id = get_my_store_id());

-- inventory
CREATE POLICY "inventory_select" ON inventory FOR SELECT USING (store_id = get_my_store_id());
CREATE POLICY "inventory_insert" ON inventory FOR INSERT WITH CHECK (store_id = get_my_store_id());
CREATE POLICY "inventory_update" ON inventory FOR UPDATE USING (store_id = get_my_store_id());
CREATE POLICY "inventory_delete" ON inventory FOR DELETE USING (store_id = get_my_store_id());

-- customers
CREATE POLICY "customers_select" ON customers FOR SELECT USING (store_id = get_my_store_id());
CREATE POLICY "customers_insert" ON customers FOR INSERT WITH CHECK (store_id = get_my_store_id());
CREATE POLICY "customers_update" ON customers FOR UPDATE USING (store_id = get_my_store_id());
CREATE POLICY "customers_delete" ON customers FOR DELETE USING (store_id = get_my_store_id());

-- introducers
CREATE POLICY "introducers_select" ON introducers FOR SELECT USING (store_id = get_my_store_id());
CREATE POLICY "introducers_insert" ON introducers FOR INSERT WITH CHECK (store_id = get_my_store_id());
CREATE POLICY "introducers_update" ON introducers FOR UPDATE USING (store_id = get_my_store_id());
CREATE POLICY "introducers_delete" ON introducers FOR DELETE USING (store_id = get_my_store_id());

-- bookings
CREATE POLICY "bookings_select" ON bookings FOR SELECT USING (store_id = get_my_store_id());
CREATE POLICY "bookings_insert" ON bookings FOR INSERT WITH CHECK (store_id = get_my_store_id());
CREATE POLICY "bookings_update" ON bookings FOR UPDATE USING (store_id = get_my_store_id());
CREATE POLICY "bookings_delete" ON bookings FOR DELETE USING (store_id = get_my_store_id());

-- consultations
CREATE POLICY "consultations_select" ON consultations FOR SELECT USING (store_id = get_my_store_id());
CREATE POLICY "consultations_insert" ON consultations FOR INSERT WITH CHECK (store_id = get_my_store_id());
CREATE POLICY "consultations_update" ON consultations FOR UPDATE USING (store_id = get_my_store_id());
CREATE POLICY "consultations_delete" ON consultations FOR DELETE USING (store_id = get_my_store_id());

-- orders
CREATE POLICY "orders_select" ON orders FOR SELECT USING (store_id = get_my_store_id());
CREATE POLICY "orders_insert" ON orders FOR INSERT WITH CHECK (store_id = get_my_store_id());
CREATE POLICY "orders_update" ON orders FOR UPDATE USING (store_id = get_my_store_id());
CREATE POLICY "orders_delete" ON orders FOR DELETE USING (store_id = get_my_store_id());

-- sales
CREATE POLICY "sales_select" ON sales FOR SELECT USING (store_id = get_my_store_id());
CREATE POLICY "sales_insert" ON sales FOR INSERT WITH CHECK (store_id = get_my_store_id());
CREATE POLICY "sales_update" ON sales FOR UPDATE USING (store_id = get_my_store_id());
CREATE POLICY "sales_delete" ON sales FOR DELETE USING (store_id = get_my_store_id());

-- shipping
CREATE POLICY "shipping_select" ON shipping FOR SELECT USING (store_id = get_my_store_id());
CREATE POLICY "shipping_insert" ON shipping FOR INSERT WITH CHECK (store_id = get_my_store_id());
CREATE POLICY "shipping_update" ON shipping FOR UPDATE USING (store_id = get_my_store_id());
CREATE POLICY "shipping_delete" ON shipping FOR DELETE USING (store_id = get_my_store_id());

-- rentals
CREATE POLICY "rentals_select" ON rentals FOR SELECT USING (store_id = get_my_store_id());
CREATE POLICY "rentals_insert" ON rentals FOR INSERT WITH CHECK (store_id = get_my_store_id());
CREATE POLICY "rentals_update" ON rentals FOR UPDATE USING (store_id = get_my_store_id());
CREATE POLICY "rentals_delete" ON rentals FOR DELETE USING (store_id = get_my_store_id());

-- repairs
CREATE POLICY "repairs_select" ON repairs FOR SELECT USING (store_id = get_my_store_id());
CREATE POLICY "repairs_insert" ON repairs FOR INSERT WITH CHECK (store_id = get_my_store_id());
CREATE POLICY "repairs_update" ON repairs FOR UPDATE USING (store_id = get_my_store_id());
CREATE POLICY "repairs_delete" ON repairs FOR DELETE USING (store_id = get_my_store_id());

-- gold_transactions
CREATE POLICY "gold_tx_select" ON gold_transactions FOR SELECT USING (store_id = get_my_store_id());
CREATE POLICY "gold_tx_insert" ON gold_transactions FOR INSERT WITH CHECK (store_id = get_my_store_id());
CREATE POLICY "gold_tx_update" ON gold_transactions FOR UPDATE USING (store_id = get_my_store_id());
CREATE POLICY "gold_tx_delete" ON gold_transactions FOR DELETE USING (store_id = get_my_store_id());

-- taxes
CREATE POLICY "taxes_select" ON taxes FOR SELECT USING (store_id = get_my_store_id());
CREATE POLICY "taxes_insert" ON taxes FOR INSERT WITH CHECK (store_id = get_my_store_id());
CREATE POLICY "taxes_update" ON taxes FOR UPDATE USING (store_id = get_my_store_id());
CREATE POLICY "taxes_delete" ON taxes FOR DELETE USING (store_id = get_my_store_id());

-- companies
CREATE POLICY "companies_select" ON companies FOR SELECT USING (store_id = get_my_store_id());
CREATE POLICY "companies_insert" ON companies FOR INSERT WITH CHECK (store_id = get_my_store_id());
CREATE POLICY "companies_update" ON companies FOR UPDATE USING (store_id = get_my_store_id());
CREATE POLICY "companies_delete" ON companies FOR DELETE USING (store_id = get_my_store_id());

-- sms_logs
CREATE POLICY "sms_select" ON sms_logs FOR SELECT USING (store_id = get_my_store_id());
CREATE POLICY "sms_insert" ON sms_logs FOR INSERT WITH CHECK (store_id = get_my_store_id());

-- messages
CREATE POLICY "messages_select" ON messages FOR SELECT USING (store_id = get_my_store_id());
CREATE POLICY "messages_insert" ON messages FOR INSERT WITH CHECK (store_id = get_my_store_id());

-- posts
CREATE POLICY "posts_select" ON posts FOR SELECT USING (store_id = get_my_store_id());
CREATE POLICY "posts_insert" ON posts FOR INSERT WITH CHECK (store_id = get_my_store_id());
CREATE POLICY "posts_update" ON posts FOR UPDATE USING (store_id = get_my_store_id());
CREATE POLICY "posts_delete" ON posts FOR DELETE USING (store_id = get_my_store_id());

-- schedules
CREATE POLICY "schedules_select" ON schedules FOR SELECT USING (store_id = get_my_store_id());
CREATE POLICY "schedules_insert" ON schedules FOR INSERT WITH CHECK (store_id = get_my_store_id());
CREATE POLICY "schedules_update" ON schedules FOR UPDATE USING (store_id = get_my_store_id());
CREATE POLICY "schedules_delete" ON schedules FOR DELETE USING (store_id = get_my_store_id());

-- staff
CREATE POLICY "staff_select" ON staff FOR SELECT USING (store_id = get_my_store_id());
CREATE POLICY "staff_insert" ON staff FOR INSERT WITH CHECK (store_id = get_my_store_id());
CREATE POLICY "staff_update" ON staff FOR UPDATE USING (store_id = get_my_store_id());
CREATE POLICY "staff_delete" ON staff FOR DELETE USING (store_id = get_my_store_id());

-- login_history
CREATE POLICY "login_select" ON login_history FOR SELECT USING (store_id = get_my_store_id());
CREATE POLICY "login_insert" ON login_history FOR INSERT WITH CHECK (store_id = get_my_store_id());

-- code_categories
CREATE POLICY "codes_select" ON code_categories FOR SELECT USING (store_id = get_my_store_id());
CREATE POLICY "codes_insert" ON code_categories FOR INSERT WITH CHECK (store_id = get_my_store_id());
CREATE POLICY "codes_update" ON code_categories FOR UPDATE USING (store_id = get_my_store_id());
CREATE POLICY "codes_delete" ON code_categories FOR DELETE USING (store_id = get_my_store_id());

-- material_codes
CREATE POLICY "materials_select" ON material_codes FOR SELECT USING (store_id = get_my_store_id());
CREATE POLICY "materials_insert" ON material_codes FOR INSERT WITH CHECK (store_id = get_my_store_id());
CREATE POLICY "materials_update" ON material_codes FOR UPDATE USING (store_id = get_my_store_id());
CREATE POLICY "materials_delete" ON material_codes FOR DELETE USING (store_id = get_my_store_id());

-- business_info
CREATE POLICY "bizinfo_select" ON business_info FOR SELECT USING (store_id = get_my_store_id());
CREATE POLICY "bizinfo_insert" ON business_info FOR INSERT WITH CHECK (store_id = get_my_store_id());
CREATE POLICY "bizinfo_update" ON business_info FOR UPDATE USING (store_id = get_my_store_id());
CREATE POLICY "bizinfo_delete" ON business_info FOR DELETE USING (store_id = get_my_store_id());

-- ============================================================================
-- 19. 초기 매장 세팅 (처음 실행 시 아래 주석을 해제하고 실행하세요)
-- ============================================================================

-- 매장 생성 예시:
-- INSERT INTO stores (name, owner_name, phone, address)
-- VALUES ('한국금거래소 안성점', '오대표', '031-xxx-xxxx', '경기도 안성시...');

-- 프로필 생성 예시 (Supabase Auth에서 사용자 생성 후):
-- INSERT INTO profiles (id, store_id, display_name, role)
-- VALUES ('여기에-auth-user-uuid', '여기에-store-uuid', '오대표', 'admin');

-- ============================================================================
-- 완료! 총 26개 테이블, 인덱스, 트리거, RLS 정책이 생성되었습니다.
-- ============================================================================
