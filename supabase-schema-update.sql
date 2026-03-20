-- ============================================================
-- GoldERP Supabase 스키마 업데이트
-- 날짜: 2026-03-20
-- 설명: 웹 버전 v5 동기화 - 새 테이블 및 필드 추가
-- ============================================================

-- ============================================================
-- 1. purchases (발주관리) 테이블 신규 생성
-- ============================================================
CREATE TABLE IF NOT EXISTS purchases (
  id TEXT PRIMARY KEY,
  type TEXT NOT NULL DEFAULT '고객발주',           -- 고객발주 / 자체발주
  customer TEXT,                                    -- 고객명 (고객발주 시)
  product TEXT NOT NULL,                            -- 제품/품목
  supplier TEXT NOT NULL,                           -- 거래처
  order_date DATE,                                  -- 발주일
  arrival_date DATE,                                -- 입고예정일
  amount INTEGER DEFAULT 0,                         -- 금액
  status TEXT NOT NULL DEFAULT '발주요청',          -- 발주요청 / 입고대기 / 입고완료
  memo TEXT,                                        -- 메모
  barcode TEXT,                                     -- 바코드 (바코드 입고용)
  incoming_date DATE,                               -- 실제 입고일
  incoming_time TEXT,                               -- 입고 시각
  outgoing_done BOOLEAN DEFAULT FALSE,              -- 출고 완료 여부 (자체발주)
  store_id UUID REFERENCES stores(id),              -- 매장 ID
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

COMMENT ON TABLE purchases IS '발주관리 - 고객발주 및 자체발주 관리';

-- RLS 정책
ALTER TABLE purchases ENABLE ROW LEVEL SECURITY;
CREATE POLICY "purchases_store_policy" ON purchases
  FOR ALL USING (store_id = current_setting('app.store_id')::uuid);

-- ============================================================
-- 2. orders 테이블에 purchaseId 필드 추가
-- ============================================================
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'orders' AND column_name = 'purchase_id'
  ) THEN
    ALTER TABLE orders ADD COLUMN purchase_id TEXT;
    COMMENT ON COLUMN orders.purchase_id IS '연결된 발주번호 (purchases.id)';
  END IF;
END $$;

-- ============================================================
-- 3. inventory 테이블에 새 필드 추가
-- ============================================================
DO $$
BEGIN
  -- location (보관위치)
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'inventory' AND column_name = 'location'
  ) THEN
    ALTER TABLE inventory ADD COLUMN location TEXT DEFAULT '진열재고';
    COMMENT ON COLUMN inventory.location IS '보관위치: 진열재고/금고재고/주문재고';
  END IF;

  -- purchase_id (연결된 발주번호)
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'inventory' AND column_name = 'purchase_id'
  ) THEN
    ALTER TABLE inventory ADD COLUMN purchase_id TEXT;
    COMMENT ON COLUMN inventory.purchase_id IS '연결된 발주번호 (purchases.id)';
  END IF;
END $$;

-- ============================================================
-- 4. 인덱스 추가 (검색 성능)
-- ============================================================
CREATE INDEX IF NOT EXISTS idx_purchases_status ON purchases(status);
CREATE INDEX IF NOT EXISTS idx_purchases_type ON purchases(type);
CREATE INDEX IF NOT EXISTS idx_purchases_barcode ON purchases(barcode);
CREATE INDEX IF NOT EXISTS idx_inventory_location ON inventory(location);
CREATE INDEX IF NOT EXISTS idx_orders_purchase_id ON orders(purchase_id);

-- ============================================================
-- 완료 메시지
-- ============================================================
-- 이 SQL을 Supabase SQL Editor에서 실행하세요.
-- 기존 데이터에는 영향이 없습니다 (IF NOT EXISTS 사용).
