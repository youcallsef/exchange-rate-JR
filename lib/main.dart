import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const UltimateCurrencyApp());
}

class UltimateCurrencyApp extends StatelessWidget {
  const UltimateCurrencyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'محول وصرف العملات اللحظي',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF030712),
      ),
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Map<String, dynamic> rates = {};
  bool isLoading = true;
  bool isRefreshing = false;
  String searchQuery = '';
  double inputAmount = 1.0;
  Timer? _timer;

  String compareFrom = 'USD';
  String compareTo = 'EGP';

  // قاموس أسماء العملات بالعربي ودولها
  final Map<String, String> currencyArabicNames = {
    'USD': 'الدولار الأمريكي 🇺🇸',
    'EGP': 'الجنيه المصري 🇪🇬',
    'SAR': 'الريال السعودي 🇸🇦',
    'AED': 'الدرهم الإماراتي 🇦🇪',
    'KWD': 'الدينار الكويتي 🇰🇼',
    'QAR': 'الريال القطري 🇶🇦',
    'BHD': 'الدينار البحريني 🇧🇭',
    'OMR': 'الريال العماني 🇴🇲',
    'JOD': 'الدينار الأردني 🇯🇴',
    'IQD': 'الدينار العراقي 🇮🇶',
    'LBP': 'النيو ليرة اللبنانية 🇱🇧',
    'LYD': 'الدينار الليبي 🇱🇾',
    'DZD': 'الدينار الجزائري 🇩🇿',
    'MAD': 'الدرهم المغربي 🇲🇦',
    'TND': 'الدينار التونسي 🇹🇳',
    'SDG': 'الجنيه السوداني 🇸🇩',
    'YER': 'الريال اليمني 🇾🇪',
    'SYP': 'الليرة السورية 🇸🇾',
    'EUR': 'اليورو الأوروبي 🇪🇺',
    'GBP': 'الجنيه الإسترليني 🇬🇧',
    'JPY': 'الين الياباني 🇯🇵',
    'CAD': 'الدولار الكندي 🇨🇦',
    'AUD': 'الدولار الأسترالي 🇦🇺',
    'CHF': 'الفرنك السويسري 🇨🇭',
    'CNY': 'اليوان الصيني 🇨🇳',
    'RUB': 'الروبل الروسي 🇷🇺',
    'TRY': 'الليرة التركية 🇹🇷',
    'INR': 'الروبية الهندية 🇮🇳',
    'BRL': 'الريال البرازيلي 🇧🇷',
    'ZAR': 'الراند الجنوب أفريقي 🇿🇦',
    'KRW': 'الوون الكوري الجنوبي 🇰🇷',
    'KZT': 'التينغ الكازاخستاني 🇰🇿',
    'MYR': 'الرينغيت الماليزي 🇲🇾',
    'SGD': 'الدولار السنغافوري 🇸🇬',
    'SEK': 'الكرونة السويدية 🇸🇪',
    'NOK': 'الكرونة النرويجية 🇳🇴',
    'DKK': 'الكرونة الدنماركية 🇩🇰',
    'NZD': 'الدولار النيوزيلندي 🇳🇿',
    'MXN': 'البيزو المكسيكي 🇲🇽',
    'THB': 'الباهت التايلاندي 🇹🇭',
    'IDR': 'الروبية الإندونيسية 🇮🇩',
    'PKR': 'الروبية الباكستانية 🇵🇰',
  };

  // قاموس لكود العلم الدقيق لكل دولة
  final Map<String, String> countryFlagCodes = {
    'USD': 'us', 'EGP': 'eg', 'SAR': 'sa', 'AED': 'ae', 'KWD': 'kw',
    'QAR': 'qa', 'BHD': 'bh', 'OMR': 'om', 'JOD': 'jo', 'IQD': 'iq',
    'LBP': 'lb', 'LYD': 'ly', 'DZD': 'dz', 'MAD': 'ma', 'TND': 'tn',
    'SDG': 'sd', 'YER': 'ye', 'SYP': 'sy', 'EUR': 'eu', 'GBP': 'gb',
    'JPY': 'jp', 'CAD': 'ca', 'AUD': 'au', 'CHF': 'ch', 'CNY': 'cn',
    'RUB': 'ru', 'TRY': 'tr', 'INR': 'in', 'BRL': 'br', 'ZAR': 'za',
    'KRW': 'kr', 'KZT': 'kz', 'MYR': 'my', 'SGD': 'sg', 'SEK': 'se',
    'NOK': 'no', 'DKK': 'dk', 'NZD': 'nz', 'MXN': 'mx', 'THB': 'th',
    'IDR': 'id', 'PKR': 'pk',
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    fetchLiveRates(isFirstLoad: true);

    _timer = Timer.periodic(const Duration(seconds: 10), (timer) {
      fetchLiveRates(isFirstLoad: false);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> fetchLiveRates({required bool isFirstLoad}) async {
    if (isFirstLoad) {
      setState(() => isLoading = true);
    } else {
      setState(() => isRefreshing = true);
    }

    try {
      final response = await http.get(
        Uri.parse('https://open.er-api.com/v6/latest/USD'),
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data != null && data['rates'] != null) {
          setState(() {
            rates = Map<String, dynamic>.from(data['rates']);
            isLoading = false;
            isRefreshing = false;
          });
        }
      } else {
        setState(() {
          isLoading = false;
          isRefreshing = false;
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        isRefreshing = false;
      });
    }
  }

  BoxDecoration goldGradientBox({double radius = 15, double borderWidth = 1.5}) {
    return BoxDecoration(
      gradient: const LinearGradient(
        colors: [Color(0xFF8F6B29), Color(0xFFD4AF37), Color(0xFFFFF3A3), Color(0xFFD4AF37), Color(0xFF8F6B29)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: const Color(0xFFFFD700), width: borderWidth),
      boxShadow: [
        BoxShadow(color: const Color(0xFFD4AF37).withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))
      ],
    );
  }

  BoxDecoration blueGradientBox({double radius = 15}) {
    return BoxDecoration(
      gradient: const LinearGradient(
        colors: [Color(0xFF0F172A), Color(0xFF1E293B), Color(0xFF090D16)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: const Color(0xFFFFD700), width: 0.4),
      boxShadow: [
        BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 8, offset: const Offset(0, 3))
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF020617), Color(0xFF1E293B), Color(0xFF020617)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        elevation: 8,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              '⚜️ الصرف اللحظي العالمي ⚜️',
              style: TextStyle(color: Color(0xFFFFD700), fontWeight: FontWeight.bold, fontSize: 18),
            ),
            if (isRefreshing) ...[
              const SizedBox(width: 10),
              const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFFFD700)),
              ),
            ]
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFFFFD700)),
            onPressed: () => fetchLiveRates(isFirstLoad: false),
            tooltip: 'تحديث الآن',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFFFFD700),
          indicatorWeight: 3.5,
          labelColor: const Color(0xFFFFD700),
          unselectedLabelColor: Colors.white54,
          tabs: const [
            Tab(text: 'كل العملات والدول'),
            Tab(text: 'المعادن الثمينة'),
            Tab(text: 'مقارنة العملات ⚖️'),
          ],
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF030712), Color(0xFF0B132B), Color(0xFF030712)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          children: [
            // محول المبلغ الرئيسي
            Padding(
              padding: const EdgeInsets.all(14.0),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: goldGradientBox(radius: 15, borderWidth: 2),
                child: Row(
                  children: [
                    const Icon(Icons.monetization_on, color: Color(0xFF0F172A)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        keyboardType: TextInputType.number,
                        style: const TextStyle(color: Color(0xFF0F172A), fontSize: 18, fontWeight: FontWeight.bold),
                        decoration: const InputDecoration(
                          hintText: 'أدخل المبلغ بالدولار للتحويل...',
                          hintStyle: TextStyle(color: Colors.black54),
                          border: InputBorder.none,
                        ),
                        onChanged: (val) {
                          setState(() {
                            inputAmount = double.tryParse(val) ?? 1.0;
                          });
                        },
                      ),
                    ),
                    const Text('USD \$', style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 16)),
                  ],
                ),
              ),
            ),

            // خانة البحث الفوقية (تطابق الاسم بالعربي والرمز)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14.0),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: blueGradientBox(radius: 15),
                child: TextField(
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    icon: Icon(Icons.search, color: Color(0xFFFFD700)),
                    hintText: 'ابحث باسم الدولة أو العملة بالعربي...',
                    hintStyle: TextStyle(color: Colors.white38),
                    border: InputBorder.none,
                  ),
                  onChanged: (val) {
                    setState(() {
                      searchQuery = val.toLowerCase();
                    });
                  },
                ),
              ),
            ),
            const SizedBox(height: 10),

            // محتوى التبويبات
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFFFFD700)))
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        buildAllCurrenciesTab(),
                        buildMetalsTab(),
                        buildRealCompareTab(),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // 1. تبويب كل دول العالم بأسمائها العربية
  Widget buildAllCurrenciesTab() {
    var filteredKeys = rates.keys.where((code) {
      String arName = currencyArabicNames[code] ?? '';
      return code.toLowerCase().contains(searchQuery) || arName.toLowerCase().contains(searchQuery);
    }).toList();

    if (filteredKeys.isEmpty) {
      return const Center(child: Text('لا توجد نتائج مطابقة للبحث...', style: TextStyle(color: Colors.white70)));
    }

    return ListView.builder(
      itemCount: filteredKeys.length,
      itemBuilder: (context, index) {
        String code = filteredKeys[index];
        double rateValue = (rates[code] is num) ? (rates[code] as num).toDouble() : 0.0;
        double finalVal = rateValue * inputAmount;

        String displayName = currencyArabicNames[code] ?? 'عملة رسمية ($code)';
        String countryFlagCode = countryFlagCodes[code] ?? (code.length >= 2 ? code.substring(0, 2).toLowerCase() : 'us');

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: blueGradientBox(radius: 12),
          child: ListTile(
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Image.network(
                'https://flagcdn.com/w80/$countryFlagCode.png',
                width: 45,
                height: 30,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => const Icon(Icons.flag, color: Color(0xFFFFD700)),
              ),
            ),
            title: Text(displayName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
            subtitle: Text('الرمز الدولي: $code', style: const TextStyle(color: Colors.white54, fontSize: 12)),
            trailing: Text(
              finalVal.toStringAsFixed(2),
              style: const TextStyle(color: Color(0xFFFFD700), fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        );
      },
    );
  }

  // 2. تبويب المعادن الثمينة
  Widget buildMetalsTab() {
    double goldPrice = 2350.0 * inputAmount;
    double silverPrice = 28.50 * inputAmount;

    final Map<String, double> metals = {
      'الذهب (أونصة - Gold)': goldPrice,
      'الفضة (أونصة - Silver)': silverPrice,
    };

    var filteredMetals = metals.keys.where((m) => m.toLowerCase().contains(searchQuery)).toList();

    return ListView.builder(
      itemCount: filteredMetals.length,
      itemBuilder: (context, index) {
        String name = filteredMetals[index];
        double price = metals[name] ?? 0.0;

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: blueGradientBox(radius: 12),
          child: ListTile(
            leading: const CircleAvatar(
              backgroundColor: Color(0xFF1E293B),
              child: Icon(Icons.diamond_outlined, color: Color(0xFFFFD700)),
            ),
            title: Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            trailing: Text(
              '\$${price.toStringAsFixed(2)}',
              style: const TextStyle(color: Color(0xFFFFD700), fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        );
      },
    );
  }

  // 3. تبويب المقارنة بالأسماء العربية والرموز
  Widget buildRealCompareTab() {
    List<String> allOptions = rates.keys.toList();
    if (allOptions.isEmpty) {
      return const Center(child: Text('جاري تحميل بيانات المقارنة...', style: TextStyle(color: Colors.white70)));
    }

    if (!allOptions.contains(compareFrom)) compareFrom = allOptions.first;
    if (!allOptions.contains(compareTo)) compareTo = allOptions.length > 1 ? allOptions[1] : allOptions.first;

    double rateFrom = (rates[compareFrom] is num) ? (rates[compareFrom] as num).toDouble() : 1.0;
    double rateTo = (rates[compareTo] is num) ? (rates[compareTo] as num).toDouble() : 1.0;
    
    double comparisonResult = (rateTo / rateFrom) * inputAmount;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: blueGradientBox(radius: 15),
            child: Column(
              children: [
                const Text(
                  '⚖️ نظام مقارنة العملات المباشر الحقيقي',
                  style: TextStyle(color: Color(0xFFFFD700), fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('من العملة:', style: TextStyle(color: Colors.white70, fontSize: 16)),
                    DropdownButton<String>(
                      value: compareFrom,
                      dropdownColor: const Color(0xFF0F172A),
                      style: const TextStyle(color: Color(0xFFFFD700), fontWeight: FontWeight.bold, fontSize: 14),
                      items: allOptions.map((code) {
                        String name = currencyArabicNames[code] ?? code;
                        return DropdownMenuItem(value: code, child: Text(name));
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => compareFrom = val);
                      },
                    ),
                  ],
                ),
                const Divider(color: Colors.white24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('إلى العملة:', style: TextStyle(color: Colors.white70, fontSize: 16)),
                    DropdownButton<String>(
                      value: compareTo,
                      dropdownColor: const Color(0xFF0F172A),
                      style: const TextStyle(color: Color(0xFFFFD700), fontWeight: FontWeight.bold, fontSize: 14),
                      items: allOptions.map((code) {
                        String name = currencyArabicNames[code] ?? code;
                        return DropdownMenuItem(value: code, child: Text(name));
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => compareTo = val);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 25),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: goldGradientBox(radius: 15, borderWidth: 2),
            child: Column(
              children: [
                Text(
                  'نتيجة المقارنة والتحويل المباشر:',
                  style: TextStyle(color: Colors.black.withOpacity(0.7), fontSize: 14, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Text(
                  '$inputAmount ${currencyArabicNames[compareFrom] ?? compareFrom} =',
                  style: const TextStyle(color: Color(0xFF0F172A), fontSize: 16, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  '${comparisonResult.toStringAsFixed(4)} ${currencyArabicNames[compareTo] ?? compareTo}',
                  style: const TextStyle(color: Color(0xFF0F172A), fontSize: 22, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
