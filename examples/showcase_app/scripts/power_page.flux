// ==========================================
// 🧪 Flux 實驗室 (Power Demo)
// 展示: 自定義組件, 複雜運算, 狀態機, 錯誤處理
// ==========================================

// 1. 自定義組件 (Components)
function Section(title, child) {
  return Container({
    margin: EdgeInsets.symmetric({vertical: 8, horizontal: 16}),
    padding: EdgeInsets.all(16),
    decoration: BoxDecoration({
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow({
          color: Colors.black12,
          blurRadius: 8,
          offset: Offset(0, 4)
        })
      ]
    }),
    child: Column({
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row({
          children: [
            Icon(Icons.science, {color: Colors.indigo, size: 20}),
            SizedBox({width: 8}),
            Text(title, {
              style: TextStyle({
                fontSize: 18, 
                fontWeight: FontWeight.bold,
                color: Colors.indigo
              })
            })
          ]
        }),
        Divider({height: 24}),
        child
      ]
    })
  });
}

// 2. 複雜運算: 質數判斷 (Pure Logic)
function isPrime(n) {
  if (n <= 1) return false;
  if (n <= 3) return true;
  if (n % 2 == 0 || n % 3 == 0) return false;
  
  i = 5;
  while (i * i <= n) {
    if (n % i == 0 || n % (i + 2) == 0) return false;
    i = i + 6;
  }
  return true;
}

// 狀態定義
state = {
  primeInput: 99991, // 預設一個大質數
  isPrimeResult: null,
  calcTime: 0,
  
  // 訂單狀態機
  orderStatus: 'pending', // pending -> paid -> shipped -> delivered
  orderLog: ['訂單已建立 (Pending)'],
  
  // 錯誤處理
  cameraStatus: '未檢測'
};

// 運算函數
function checkPrime() {
  start = DateTime.now().millisecondsSinceEpoch;
  result = isPrime(state.primeInput);
  end = DateTime.now().millisecondsSinceEpoch;
  
  state.isPrimeResult = result;
  state.calcTime = end - start;
  update(); // 觸發 UI 更新
}

// 訂單狀態流轉
function nextOrderStatus() {
  current = state.orderStatus;
  
  if (current == 'pending') {
    state.orderStatus = 'paid';
    state.orderLog.add('✅ 訂單已付款 (Paid)');
  } else if (current == 'paid') {
    state.orderStatus = 'shipped';
    state.orderLog.add('🚚 訂單已發貨 (Shipped)');
  } else if (current == 'shipped') {
    state.orderStatus = 'delivered';
    state.orderLog.add('📦 訂單已送達 (Delivered)');
  } else {
    state.orderStatus = 'pending';
    state.orderLog = ['🔄 訂單重置 (Pending)'];
  }
  
  update();
}

// 錯誤邊界測試
function tryOpenCamera() {
  try {
    // 試圖調用不存在的原生函數
    openCamera(); 
  } catch (e) {
    state.cameraStatus = '🛑 攔截成功: ' + e.toString();
    showToast('安全沙盒: 攔截未授權調用');
    update();
  }
}

// UI 構建
Widget.build(context, {
  return ListView({
    padding: EdgeInsets.only({bottom: 32}),
    children: [
      
      // 區塊 1: 複雜運算能力
      Section('邏輯運算能力', Column({
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Flux VM 具備完整運算能力，可執行複雜演算法。'),
          SizedBox({height: 12}),
          TextField({
            decoration: InputDecoration({
              labelText: '輸入數字判斷質數',
              border: OutlineInputBorder()
            }),
            keyboardType: TextInputType.number,
            onChanged: (val) => state.primeInput = int.parse(val)
          }),
          SizedBox({height: 12}),
          ElevatedButton({
            onPressed: checkPrime,
            child: Text('開始計算')
          }),
          SizedBox({height: 12}),
          if (state.isPrimeResult != null)
            Container({
              padding: EdgeInsets.all(12),
              color: state.isPrimeResult ? Colors.green[50] : Colors.red[50],
              child: Column({
                children: [
                  Text(state.isPrimeResult ? '是質數 (Prime)' : '非質數', {
                    style: TextStyle({
                      fontSize: 20, 
                      fontWeight: FontWeight.bold,
                      color: state.isPrimeResult ? Colors.green : Colors.red
                    })
                  }),
                  Text('耗時: ' + state.calcTime.toString() + 'ms')
                ]
              })
            })
        ]
      })),

      // 區塊 2: 狀態機模擬
      Section('狀態機 (State Machine)', Column({
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('完全由腳本控制的業務狀態流轉：'),
          SizedBox({height: 12}),
          Row({
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.payment, {color: state.orderStatus == 'pending' ? Colors.grey : Colors.green}),
              Icon(Icons.arrow_right),
              Icon(Icons.inventory, {color: state.orderStatus == 'paid' || state.orderStatus == 'shipped' || state.orderStatus == 'delivered' ? Colors.green : Colors.grey}),
              Icon(Icons.arrow_right),
              Icon(Icons.local_shipping, {color: state.orderStatus == 'shipped' || state.orderStatus == 'delivered' ? Colors.green : Colors.grey}),
              Icon(Icons.arrow_right),
              Icon(Icons.check_circle, {color: state.orderStatus == 'delivered' ? Colors.green : Colors.grey}),
            ]
          }),
          SizedBox({height: 16}),
          ElevatedButton({
            style: ElevatedButton.styleFrom({
              backgroundColor: Colors.indigo,
              foregroundColor: Colors.white
            }),
            onPressed: nextOrderStatus,
            child: Text('推進狀態 >>')
          }),
          SizedBox({height: 16}),
          Container({
            height: 100,
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration({
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8)
            }),
            child: ListView({
              children: state.orderLog.map((log) => Text(log)).toList()
            })
          })
        ]
      })),

      // 區塊 3: 安全沙盒與錯誤處理
      Section('安全沙盒 (Sandbox)', Column({
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Flux 腳本無法調用未授權的原生 API。試試看調用相機：'),
          SizedBox({height: 12}),
          OutlinedButton({
            onPressed: tryOpenCamera,
            child: Text('📷 嘗試開啟相機 (Unauthorized)')
          }),
          SizedBox({height: 8}),
          Text(state.cameraStatus, {
            style: TextStyle({
              color: Colors.red,
              fontWeight: FontWeight.bold
            })
          })
        ]
      }))

    ]
  });
});
