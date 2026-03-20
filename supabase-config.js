/**
 * GoldERP Supabase 설정 및 헬퍼 함수
 *
 * 설정 방법:
 * 1. https://supabase.com 에서 프로젝트를 생성하세요
 * 2. 아래의 SUPABASE_URL과 SUPABASE_ANON_KEY를 프로젝트 설정에서 복사하세요
 * 3. store_id는 각 사용자의 실제 가게 ID로 설정하세요
 */

// ============================================
// Supabase 클라이언트 초기화
// ============================================

// ⚠️ 여기에 Supabase URL과 Anonymous Key를 입력하세요
const SUPABASE_URL = 'https://wgfirtaxagyshuizuesn.supabase.co';
const SUPABASE_ANON_KEY = 'sb_publishable_Ujqewjhp2fvBYbWY3nKqqA_QDmpU341';

// Supabase 클라이언트 (CDN에서 로드된 후 사용 가능)
// 주의: window.supabase는 CDN이 사용하므로, 클라이언트는 별도 변수명 사용
let _supabaseClient = null;

// 초기화 함수
async function initSupabase() {
  if (!_supabaseClient) {
    // CDN이 window.supabase에 라이브러리를 로드함
    const lib = window.supabase;
    if (!lib || !lib.createClient) {
      throw new Error('Supabase 라이브러리가 로드되지 않았습니다. 인터넷 연결을 확인하세요.');
    }
    _supabaseClient = lib.createClient(SUPABASE_URL, SUPABASE_ANON_KEY);
    console.log('Supabase 클라이언트 초기화 완료');
  }
  return _supabaseClient;
}

// ============================================
// 인증 함수
// ============================================

/**
 * 이메일과 비밀번호로 로그인
 * @param {string} email - 사용자 이메일
 * @param {string} password - 비밀번호
 * @returns {Promise<{user, session, error}>}
 */
async function login(email, password) {
  const client = _supabaseClient || await initSupabase();

  try {
    const { data, error } = await client.auth.signInWithPassword({
      email,
      password,
    });

    if (error) {
      console.error('로그인 실패:', error.message);
      return { user: null, session: null, error };
    }

    console.log('로그인 성공');
    return { user: data.user, session: data.session, error: null };
  } catch (err) {
    console.error('로그인 중 오류:', err);
    return { user: null, session: null, error: err };
  }
}

/**
 * 로그아웃
 * @returns {Promise<{error}>}
 */
async function logout() {
  const client = _supabaseClient || await initSupabase();

  try {
    const { error } = await client.auth.signOut();

    if (error) {
      console.error('로그아웃 실패:', error.message);
      return { error };
    }

    console.log('로그아웃 성공');
    return { error: null };
  } catch (err) {
    console.error('로그아웃 중 오류:', err);
    return { error: err };
  }
}

/**
 * 현재 로그인한 사용자 정보 조회
 * @returns {Promise<{user, error}>}
 */
async function getUser() {
  const client = _supabaseClient || await initSupabase();

  try {
    const { data: { user }, error } = await client.auth.getUser();

    if (error) {
      console.error('사용자 정보 조회 실패:', error.message);
      return { user: null, error };
    }

    return { user, error: null };
  } catch (err) {
    console.error('사용자 정보 조회 중 오류:', err);
    return { user: null, error: err };
  }
}

/**
 * 인증 상태 변화 감시 및 콜백 실행
 * @param {function} callback - 상태 변화 시 호출될 콜백 함수
 * @returns {function} 구독 해제 함수
 */
async function onAuthChange(callback) {
  const client = _supabaseClient || await initSupabase();

  if (!client) {
    console.error('Supabase 클라이언트가 초기화되지 않았습니다');
    return () => {};
  }

  const { data: { subscription } } = client.auth.onAuthStateChange((event, session) => {
    callback(event, session);
  });

  // 구독 해제 함수 반환
  return () => subscription?.unsubscribe();
}

// ============================================
// CRUD 헬퍼 함수
// ============================================

/**
 * 현재 사용자의 store_id 가져오기
 * @returns {Promise<string>} store_id
 */
async function getStoreId() {
  const { user } = await getUser();

  if (!user) {
    throw new Error('로그인이 필요합니다');
  }

  // store_id는 user_metadata에서 조회하거나, 별도의 사용자 정보 테이블에서 조회
  return user.user_metadata?.store_id || user.id;
}

/**
 * 모든 행 조회 (자동으로 store_id 필터 적용)
 * @param {string} table - 테이블 이름
 * @param {object} filters - 추가 필터 조건 (선택사항)
 * @returns {Promise<{data, error}>}
 */
async function fetchAll(table, filters = {}) {
  const client = _supabaseClient || await initSupabase();

  try {
    const storeId = await getStoreId();

    let query = client.from(table).select('*').eq('store_id', storeId);

    // 추가 필터 적용
    Object.entries(filters).forEach(([key, value]) => {
      if (value !== undefined && value !== null) {
        query = query.eq(key, value);
      }
    });

    const { data, error } = await query;

    if (error) {
      console.error(`${table} 조회 실패:`, error.message);
      return { data: null, error };
    }

    return { data, error: null };
  } catch (err) {
    console.error(`${table} 조회 중 오류:`, err);
    return { data: null, error: err };
  }
}

/**
 * 단일 행 조회 (자동으로 store_id 필터 적용)
 * @param {string} table - 테이블 이름
 * @param {string|number} id - 행의 id
 * @returns {Promise<{data, error}>}
 */
async function fetchOne(table, id) {
  const client = _supabaseClient || await initSupabase();

  try {
    const storeId = await getStoreId();

    const { data, error } = await client
      .from(table)
      .select('*')
      .eq('store_id', storeId)
      .eq('id', id)
      .single();

    if (error) {
      console.error(`${table} (id: ${id}) 조회 실패:`, error.message);
      return { data: null, error };
    }

    return { data, error: null };
  } catch (err) {
    console.error(`${table} 조회 중 오류:`, err);
    return { data: null, error: err };
  }
}

/**
 * 새 행 삽입 (자동으로 store_id 추가)
 * @param {string} table - 테이블 이름
 * @param {object} data - 삽입할 데이터
 * @returns {Promise<{data, error}>}
 */
async function insertRow(table, data) {
  const client = _supabaseClient || await initSupabase();

  try {
    const storeId = await getStoreId();

    const newData = {
      ...data,
      store_id: storeId,
    };

    const { data: result, error } = await client
      .from(table)
      .insert([newData])
      .select();

    if (error) {
      console.error(`${table} 삽입 실패:`, error.message);
      return { data: null, error };
    }

    return { data: result, error: null };
  } catch (err) {
    console.error(`${table} 삽입 중 오류:`, err);
    return { data: null, error: err };
  }
}

/**
 * 행 업데이트 (store_id 검증 포함)
 * @param {string} table - 테이블 이름
 * @param {string|number} id - 행의 id
 * @param {object} data - 업데이트할 데이터
 * @returns {Promise<{data, error}>}
 */
async function updateRow(table, id, data) {
  const client = _supabaseClient || await initSupabase();

  try {
    const storeId = await getStoreId();

    const { data: result, error } = await client
      .from(table)
      .update(data)
      .eq('store_id', storeId)
      .eq('id', id)
      .select();

    if (error) {
      console.error(`${table} (id: ${id}) 업데이트 실패:`, error.message);
      return { data: null, error };
    }

    return { data: result, error: null };
  } catch (err) {
    console.error(`${table} 업데이트 중 오류:`, err);
    return { data: null, error: err };
  }
}

/**
 * 행 삭제 (store_id 검증 포함)
 * @param {string} table - 테이블 이름
 * @param {string|number} id - 행의 id
 * @returns {Promise<{error}>}
 */
async function deleteRow(table, id) {
  const client = _supabaseClient || await initSupabase();

  try {
    const storeId = await getStoreId();

    const { error } = await client
      .from(table)
      .delete()
      .eq('store_id', storeId)
      .eq('id', id);

    if (error) {
      console.error(`${table} (id: ${id}) 삭제 실패:`, error.message);
      return { error };
    }

    return { error: null };
  } catch (err) {
    console.error(`${table} 삭제 중 오류:`, err);
    return { error: err };
  }
}

// ============================================
// 실시간 구독 함수
// ============================================

/**
 * 테이블의 실시간 변경 사항 구독
 * @param {string} table - 테이블 이름
 * @param {function} callback - 변경 발생 시 호출될 콜백 함수
 * @returns {function} 구독 해제 함수
 */
async function subscribe(table, callback) {
  const client = _supabaseClient || await initSupabase();

  try {
    const storeId = await getStoreId();

    const channel = client
      .channel(`${table}-changes`)
      .on(
        'postgres_changes',
        {
          event: '*', // INSERT, UPDATE, DELETE 모두 감시
          schema: 'public',
          table: table,
          filter: `store_id=eq.${storeId}`,
        },
        (payload) => {
          callback(payload);
        }
      )
      .subscribe((status) => {
        console.log(`${table} 구독 상태:`, status);
      });

    // 구독 해제 함수 반환
    return async () => {
      await client.removeChannel(channel);
    };
  } catch (err) {
    console.error(`${table} 구독 중 오류:`, err);
    return () => {};
  }
}

// ============================================
// 모듈 내보내기
// ============================================

if (typeof module !== 'undefined' && module.exports) {
  module.exports = {
    initSupabase,
    login,
    logout,
    getUser,
    onAuthChange,
    getStoreId,
    fetchAll,
    fetchOne,
    insertRow,
    updateRow,
    deleteRow,
    subscribe,
  };
}