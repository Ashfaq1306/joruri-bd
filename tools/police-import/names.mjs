// Hand-checked facts the PDF does not state: which district each number
// block belongs to, rows that are not police stations, and standard English
// and Bangla names (the PDF spells many names loosely: "Kotoali", "Bongsal").

// 01320-XXX……: the three digits after 01320 identify the district.
export const DISTRICT_OF_BLOCK = {
  '089': 'dhaka', '090': 'narayanganj', '091': 'narsingdi', '092': 'gazipur', '093': 'munshiganj', '094': 'manikganj',
  '095': 'kishoreganj', '096': 'tangail', '097': 'faridpur', '098': 'madaripur', '099': 'gopalganj', '100': 'shariatpur',
  '101': 'rajbari', '103': 'mymensingh', '104': 'netrokona', '105': 'jamalpur', '106': 'sherpur',
  '107': 'chattogram', '108': 'coxs-bazar', '109': 'rangamati', '110': 'khagrachhari', '111': 'noakhali', '112': 'lakshmipur',
  '113': 'feni', '114': 'cumilla', '115': 'brahmanbaria', '116': 'chandpur',
  '117': 'sylhet', '118': 'habiganj', '119': 'moulvibazar', '120': 'sunamganj', '121': 'sunamganj',
  '122': 'rajshahi', '123': 'naogaon', '124': 'natore', '125': 'chapainawabganj', '126': 'bogura', '127': 'joypurhat',
  '128': 'pabna', '129': 'sirajganj',
  '131': 'rangpur', '132': 'gaibandha', '133': 'kurigram', '134': 'lalmonirhat', '135': 'nilphamari', '136': 'dinajpur',
  '137': 'thakurgaon', '138': 'panchagarh',
  '140': 'khulna', '141': 'bagerhat', '142': 'satkhira', '143': 'jashore', '144': 'jhenaidah', '145': 'magura', '146': 'narail',
  '147': 'kushtia', '148': 'chuadanga', '149': 'meherpur',
  '151': 'barishal', '152': 'bhola', '153': 'pirojpur', '154': 'jhalokati', '155': 'patuakhali', '156': 'barguna',
};

// Each district's Sadar station is numbered at the end of the block before
// it (Cumilla Kotwali = 01320-113996), and block 110 holds two districts.
export const BLOCK_EXCEPTIONS = {
  '01320109981': 'khagrachhari', '01320110981': 'noakhali', '01320111976': 'lakshmipur', '01320112976': 'feni',
  '01320113996': 'cumilla',
  '01320110476': 'bandarban', '01320110502': 'bandarban', '01320110528': 'bandarban', '01320110554': 'bandarban',
  '01320110580': 'bandarban', '01320110606': 'bandarban', '01320110632': 'bandarban',
  '01320118021': 'sylhet', '01320118047': 'sylhet',
};

export const SKIP = new Set([
  '01320059119', // KMP "OC DB" (Detective Branch, not a thana)
  '01320119957', // Moulvibazar "OC DB"
  '01320120003', // "OC Watch"
  '01320107783', // "OC invest. Satkaniya" (second number of Satkaniya)
  // Out of sequence in the source (probably misprinted); left out until checked:
  '01320154123', // Rajpur, Jhalokati (block runs …171, …197, [?], …249)
  '01320152333', // Shashibhushan, Bhola (block runs …337, [?], …389)
]);

// en/bn without the word "Thana"; `dmp` = name on the DMP website when it differs.
const n = (en, bn, extra = {}) => ({ en, bn, ...extra });
export const NAMES = {
  // ---------- DMP ----------
  '01320039492': n('Ramna Model Thana', 'রমনা মডেল থানা'), '01320039520': n('Shahbagh', 'শাহবাগ'),
  '01320039548': n('Dhanmondi Model Thana', 'ধানমন্ডি মডেল থানা', { dmp: 'Dhanmondi' }), '01320039576': n('New Market', 'নিউমার্কেট'),
  '01320039604': n('Hazaribagh', 'হাজারীবাগ', { dmp: 'Hazaribag' }), '01320039632': n('Kalabagan', 'কলাবাগান'),
  '01320039809': n('Kotwali', 'কোতোয়ালী'), '01320039837': n('Lalbagh', 'লালবাগ'), '01320039865': n('Bangshal', 'বংশাল'),
  '01320039893': n('Chawkbazar', 'চকবাজার', { dmp: 'Chalkbazar' }), '01320039921': n('Kamrangirchar', 'কামরাঙ্গীরচর'),
  '01320039949': n('Sutrapur', 'সূত্রাপুর'), '01320040132': n('Paltan Model Thana', 'পল্টন মডেল থানা', { dmp: 'Paltan' }),
  '01320040160': n('Motijheel', 'মতিঝিল'), '01320040188': n('Sabujbagh', 'সবুজবাগ', { dmp: 'Sabujbag' }),
  '01320040216': n('Khilgaon', 'খিলগাঁও', { dmp: 'Khilgoan' }), '01320040244': n('Rampura', 'রামপুরা'), '01320040272': n('Mugda', 'মুগদা'),
  '01320040300': n('Shahjahanpur', 'শাহজাহানপুর'), '01320040481': n('Shyampur', 'শ্যামপুর'), '01320040509': n('Jatrabari', 'যাত্রাবাড়ী', { dmp: 'Jattrabari' }),
  '01320040537': n('Demra', 'ডেমরা'), '01320040565': n('Kadamtali', 'কদমতলী', { dmp: 'Kodomtali' }), '01320040593': n('Gendaria', 'গেন্ডারিয়া', { dmp: 'Gandaria' }),
  '01320040621': n('Wari', 'ওয়ারী'), '01320040802': n('Tejgaon', 'তেজগাঁও', { dmp: 'Tejgoan' }),
  '01320040830': n('Tejgaon Industrial Area', 'তেজগাঁও শিল্পাঞ্চল', { dmp: 'Tejgoan Industrial' }),
  '01320040858': n('Mohammadpur', 'মোহাম্মদপুর'), '01320040886': n('Adabor', 'আদাবর'),
  '01320040914': n('Sher-e-Bangla Nagar', 'শেরেবাংলা নগর', { dmp: 'Sher e Bangla Nagar' }), '01320040942': n('Hatirjheel', 'হাতিরঝিল'),
  '01320041122': n('Mirpur Model Thana', 'মিরপুর মডেল থানা', { dmp: 'Mirpur Model' }), '01320041150': n('Shah Ali', 'শাহ আলী'),
  '01320041178': n('Pallabi', 'পল্লবী'), '01320041206': n('Kafrul', 'কাফরুল'), '01320041234': n('Rupnagar', 'রূপনগর'),
  '01320041262': n('Bhashantek', 'ভাসানটেক', { dmp: 'Bsahantek' }), '01320041290': n('Darus Salam', 'দারুস সালাম', { dmp: 'Darus-Salam' }),
  '01320041472': n('Gulshan', 'গুলশান'), '01320041500': n('Badda', 'বাড্ডা'), '01320041528': n('Khilkhet', 'খিলক্ষেত'),
  '01320041556': n('Cantonment', 'ক্যান্টনমেন্ট'), '01320041584': n('Vatara', 'ভাটারা'), '01320041612': n('Banani', 'বনানী'),
  '01320041789': n('Uttara East', 'উত্তরা পূর্ব'), '01320041817': n('Uttara West', 'উত্তরা পশ্চিম'), '01320041845': n('Turag', 'তুরাগ'),
  '01320041873': n('Biman Bandar (Airport)', 'বিমানবন্দর', { dmp: 'Bimanbandar' }), '01320041901': n('Dakshinkhan', 'দক্ষিণখান', { dmp: 'Dakshin Khan' }),
  '01320041929': n('Uttarkhan', 'উত্তরখান', { dmp: 'Uttar Khan' }),
  // ---------- CMP ----------
  '01320052443': n('Chandgaon', 'চান্দগাঁও'), '01320052470': n('Panchlaish', 'পাঁচলাইশ'), '01320052497': n('Khulshi', 'খুলশী'),
  '01320052524': n('Bayazid Bostami', 'বায়েজিদ বোস্তামী'), '01320052593': n('Kotwali', 'কোতোয়ালী'), '01320052620': n('Bakalia', 'বাকলিয়া'),
  '01320052647': n('Chawkbazar', 'চকবাজার'), '01320052674': n('Sadarghat', 'সদরঘাট'), '01320052743': n('Double Mooring', 'ডবলমুরিং'),
  '01320052770': n('Halishahar', 'হালিশহর'), '01320052797': n('Pahartali', 'পাহাড়তলী'), '01320052824': n('Akbar Shah', 'আকবরশাহ'),
  '01320052893': n('Bandar (Port)', 'বন্দর'), '01320052920': n('EPZ', 'ইপিজেড'), '01320052947': n('Patenga', 'পতেঙ্গা'),
  '01320052974': n('Karnaphuli', 'কর্ণফুলী'),
  // ---------- KMP ----------
  '01320058382': n('Khulna Sadar', 'খুলনা সদর'), '01320058409': n('Sonadanga', 'সোনাডাঙ্গা'), '01320058436': n('Labanchara', 'লবণচরা'),
  '01320058463': n('Harintana', 'হরিণটানা'), '01320058512': n('Khalishpur', 'খালিশপুর'), '01320058539': n('Daulatpur', 'দৌলতপুর'),
  '01320058566': n('Aronghata', 'আড়ংঘাটা'), '01320058593': n('Khan Jahan Ali', 'খানজাহান আলী'),
  // ---------- RMP ----------
  '01320061499': n('Boalia', 'বোয়ালিয়া'), '01320061527': n('Rajpara', 'রাজপাড়া'), '01320061555': n('Chandrima', 'চন্দ্রিমা'),
  '01320061623': n('Motihar', 'মতিহার'), '01320061651': n('Katakhali', 'কাটাখালী'), '01320061679': n('Belpukur', 'বেলপুকুর'),
  '01320061753': n('Shah Makhdum', 'শাহ মখদুম'), '01320061781': n('Biman Bandar (Airport)', 'বিমানবন্দর'), '01320061809': n('Paba', 'পবা'),
  '01320061883': n('Kashiadanga', 'কাশিয়াডাঙ্গা'), '01320061911': n('Damkura', 'দামকুড়া'), '01320061939': n('Karnahar', 'কর্ণহার'),
  // ---------- BMP ----------
  '01320065496': n('Bandar (Port)', 'বন্দর'), '01320065524': n('University (Bishwabidyalay)', 'বিশ্ববিদ্যালয়'), '01320065606': n('Kashipur', 'কাশিপুর'),
  '01320065634': n('Biman Bandar (Airport)', 'বিমানবন্দর'), '01320065716': n('Charmonai', 'চরমোনাই'), '01320065744': n('Kawnia', 'কাউনিয়া'),
  '01320065826': n('Kotwali Model Thana', 'কোতোয়ালী মডেল থানা'), '01320065854': n('Rupatali', 'রূপাতলী'),
  // ---------- SMP ----------
  '01320067568': n('Kotwali Model Thana', 'কোতোয়ালী মডেল থানা'), '01320067594': n('Jalalabad', 'জালালাবাদ'), '01320067620': n('Biman Bandar (Airport)', 'বিমানবন্দর'),
  '01320067688': n('Dakshin Surma (South Surma)', 'দক্ষিণ সুরমা'), '01320067714': n('Moglabazar', 'মোগলাবাজার'), '01320067740': n('Shah Poran', 'শাহপরাণ'),
  // ---------- GMP ----------
  '01320070524': n('Gazipur Sadar', 'গাজীপুর সদর'), '01320070553': n('Basan', 'বাসন'), '01320070582': n('Konabari', 'কোনাবাড়ী'),
  '01320070611': n('Kashimpur', 'কাশিমপুর'), '01320070664': n('Gacha', 'গাছা'), '01320070693': n('Pubail', 'পূবাইল'),
  '01320070722': n('Tongi East', 'টঙ্গী পূর্ব'), '01320070751': n('Tongi West', 'টঙ্গী পশ্চিম'),
  // ---------- RPMP ----------
  '01320073475': n('Kotwali', 'কোতোয়ালী'), '01320073504': n('Tajhat', 'তাজহাট'), '01320073539': n('Mahiganj', 'মাহিগঞ্জ'),
  '01320073568': n('Haragach', 'হারাগাছ'), '01320073603': n('Parshuram', 'পরশুরাম'), '01320073632': n('Hazirhat', 'হাজিরহাট'),

  // ---------- district police: stations the upazila list could not name
  // (Sadar/Kotwali stations, newer thanas, unusable DGHS Bangla names) ----------
  '01320089403': n('Ashulia', 'আশুলিয়া'), '01320089481': n('South Keraniganj', 'দক্ষিণ কেরানীগঞ্জ'),
  '01320090377': n('Narayanganj Sadar Model Thana', 'নারায়ণগঞ্জ সদর মডেল থানা'), '01320090403': n('Fatullah Model Thana', 'ফতুল্লা মডেল থানা'),
  '01320090429': n('Siddhirganj', 'সিদ্ধিরগঞ্জ'), '01320091375': n('Narsingdi Model Thana', 'নরসিংদী মডেল থানা'), '01320091536': n('Madhabdi', 'মাধবদী'),
  '01320092371': n('Joydebpur', 'জয়দেবপুর'), '01320093374': n('Munshiganj Sadar', 'মুন্সিগঞ্জ সদর'), '01320094375': n('Manikganj Sadar', 'মানিকগঞ্জ সদর'),
  '01320095391': n('Kishoreganj Sadar Model Thana', 'কিশোরগঞ্জ সদর মডেল থানা'), '01320095625': n('Itna', 'ইটনা'),
  '01320096391': n('Tangail Sadar', 'টাঙ্গাইল সদর'), '01320096703': n('Bangabandhu Setu East', 'বঙ্গবন্ধু সেতু পূর্ব'),
  '01320097380': n('Faridpur Kotwali', 'ফরিদপুর কোতোয়ালী'), '01320098370': n('Madaripur Sadar Model Thana', 'মাদারীপুর সদর মডেল থানা'),
  '01320098396': n('Rajoir', 'রাজৈর'), '01320099370': n('Gopalganj Sadar', 'গোপালগঞ্জ সদর'),
  '01320100374': n('Palong Model Thana (Shariatpur Sadar)', 'পালং মডেল থানা (শরীয়তপুর সদর)'), '01320100426': n('Zajira', 'জাজিরা'),
  '01320100530': n('Sakhipur', 'সখিপুর'), '01320101369': n('Rajbari Sadar', 'রাজবাড়ী সদর'),
  '01320103191': n('Mymensingh Kotwali', 'ময়মনসিংহ কোতোয়ালী'), '01320103347': n('Pagla', 'পাগলা'),
  '01320104185': n('Netrokona Model Thana', 'নেত্রকোনা মডেল থানা'), '01320105179': n('Jamalpur Sadar', 'জামালপুর সদর'),
  '01320106169': n('Sherpur Sadar', 'শেরপুর সদর'), '01320106221': n('Nalitabari', 'নালিতাবাড়ী'),
  '01320107574': n('Zorarganj', 'জোরারগঞ্জ'), '01320107626': n('Fatikchhari', 'ফটিকছড়ি'), '01320107652': n('Bhujpur', 'ভূজপুর'),
  '01320108471': n('Cox’s Bazar Sadar Model Thana', 'কক্সবাজার সদর মডেল থানা'),
  '01320109481': n('Rangamati Kotwali', 'রাঙ্গামাটি কোতোয়ালী'), '01320109585': n('Chandraghona', 'চন্দ্রঘোনা'), '01320109715': n('Sajek', 'সাজেক'),
  '01320109981': n('Khagrachhari Sadar', 'খাগড়াছড়ি সদর'), '01320110111': n('Matiranga', 'মাটিরাঙ্গা'), '01320110189': n('Guimara', 'গুইমারা'),
  '01320110476': n('Bandarban Sadar', 'বান্দরবান সদর'),
  '01320110981': n('Sudharam Model Thana (Noakhali Sadar)', 'সুধারাম মডেল থানা (নোয়াখালী সদর)'),
  '01320111111': n('Chatkhil', 'চাটখিল'), '01320111163': n('Char Jabbar', 'চর জব্বার'),
  '01320111976': n('Lakshmipur Sadar Model Thana', 'লক্ষ্মীপুর সদর মডেল থানা'), '01320112080': n('Kamalnagar', 'কমলনগর'),
  '01320112106': n('Chandraganj', 'চন্দ্রগঞ্জ'), '01320112976': n('Feni Model Thana', 'ফেনী মডেল থানা'), '01320113002': n('Daganbhuiyan', 'দাগনভূঞা'),
  '01320113996': n('Cumilla Kotwali Model Thana', 'কুমিল্লা কোতোয়ালী মডেল থানা'), '01320114048': n('Debidwar', 'দেবিদ্বার'),
  '01320114152': n('Burichang', 'বুড়িচং'), '01320114204': n('Barura', 'বরুড়া'), '01320114386': n('Sadar Dakshin (Sadar South)', 'সদর দক্ষিণ'),
  '01320114412': n('Bangra Bazar', 'বাঙ্গরা বাজার'), '01320114438': n('Lalmai', 'লালমাই'),
  '01320116033': n('Matlab Uttar (North)', 'মতলব উত্তর'), '01320116059': n('Matlab Dakshin (South)', 'মতলব দক্ষিণ'), '01320116137': n('Faridganj', 'ফরিদগঞ্জ'),
  '01320140311': n('Paikgachha', 'পাইকগাছা'), '01320140337': n('Dacope', 'দাকোপ'),
  '01320141179': n('Bagerhat Sadar', 'বাগেরহাট সদর'), '01320141361': n('Mongla', 'মোংলা'), '01320141387': n('Rampal', 'রামপাল'),
  '01320142179': n('Satkhira Sadar', 'সাতক্ষীরা সদর'), '01320142231': n('Tala', 'তালা'), '01320142361': n('Patkelghata', 'পাটকেলঘাটা'),
  '01320143180': n('Jashore Kotwali Model Thana', 'যশোর কোতোয়ালী মডেল থানা'), '01320143206': n('Jhikargachha', 'ঝিকরগাছা'),
  '01320143258': n('Bagherpara', 'বাঘারপাড়া'), '01320143388': n('Benapole Port', 'বেনাপোল পোর্ট'),
  '01320144174': n('Jhenaidah Sadar', 'ঝিনাইদহ সদর'), '01320144278': n('Kotchandpur', 'কোটচাঁদপুর'),
  '01320145170': n('Magura Sadar', 'মাগুরা সদর'), '01320146169': n('Narail Sadar', 'নড়াইল সদর'), '01320146247': n('Naragati', 'নড়াগাতী'),
  '01320147175': n('Kushtia Model Thana', 'কুষ্টিয়া মডেল থানা'), '01320147331': n('Islamic University (IB)', 'ইবি'),
  '01320148169': n('Chuadanga Sadar', 'চুয়াডাঙ্গা সদর'), '01320148273': n('Darshana', 'দর্শনা'),
  '01320149164': n('Meherpur Sadar', 'মেহেরপুর সদর'), '01320149190': n('Gangni', 'গাংনী'),
  '01320122594': n('Godagari', 'গোদাগাড়ী'),
  '01320123590': n('Naogaon Sadar Model Thana', 'নওগাঁ সদর মডেল থানা'), '01320123694': n('Badalgachhi', 'বদলগাছী'), '01320123720': n('Mohadevpur', 'মহাদেবপুর'),
  '01320124574': n('Natore Sadar', 'নাটোর সদর'), '01320125569': n('Chapainawabganj Sadar Model Thana', 'চাঁপাইনবাবগঞ্জ সদর মডেল থানা'),
  '01320125673': n('Bholahat', 'ভোলাহাট'), '01320126601': n('Bogura Sadar', 'বগুড়া সদর'),
  '01320127569': n('Joypurhat Sadar', 'জয়পুরহাট সদর'), '01320127647': n('Kalai', 'কালাই'),
  '01320128586': n('Pabna Sadar', 'পাবনা সদর'), '01320128638': n('Atgharia', 'আটঘরিয়া'), '01320128690': n('Bhangura', 'ভাঙ্গুড়া'),
  '01320128794': n('Santhia', 'সাঁথিয়া'), '01320128820': n('Ataikula', 'আতাইকুলা'), '01320128846': n('Aminpur', 'আমিনপুর'),
  '01320129590': n('Sirajganj Sadar', 'সিরাজগঞ্জ সদর'), '01320129694': n('Tarash', 'তাড়াশ'),
  '01320129824': n('Bangabandhu Setu West', 'বঙ্গবন্ধু সেতু পশ্চিম'), '01320129850': n('Salanga', 'সলঙ্গা'), '01320129876': n('Enayetpur', 'এনায়েতপুর'),
  '01320131381': n('Rangpur Kotwali', 'রংপুর কোতোয়ালী'), '01320132376': n('Gaibandha Sadar', 'গাইবান্ধা সদর'),
  '01320133386': n('Kurigram Sadar', 'কুড়িগ্রাম সদর'), '01320133490': n('Bhurungamari', 'ভুরুঙ্গামারী'),
  '01320133620': n('Dushmara', 'দুসমারা'), '01320133646': n('Kachakata', 'কচাকাটা'),
  '01320134371': n('Lalmonirhat Sadar', 'লালমনিরহাট সদর'), '01320135376': n('Nilphamari Sadar', 'নীলফামারী সদর'),
  '01320136391': n('Dinajpur Kotwali', 'দিনাজপুর কোতোয়ালী'), '01320136677': n('Ghoraghat', 'ঘোড়াঘাট'),
  '01320137376': n('Thakurgaon Sadar', 'ঠাকুরগাঁও সদর'), '01320137506': n('Ruhia', 'রুহিয়া'),
  '01320138371': n('Panchagarh Sadar', 'পঞ্চগড় সদর'), '01320138449': n('Tetulia', 'তেঁতুলিয়া'),
  '01320151238': n('Wazirpur', 'উজিরপুর'), '01320151394': n('Mehendiganj', 'মেহেন্দিগঞ্জ'), '01320151420': n('Kazirhat', 'কাজিরহাট'),
  '01320154171': n('Jhalokati Sadar', 'ঝালকাঠি সদর'), '01320154197': n('Nalchity', 'নলছিটি'),
  '01320152181': n('Bhola Model Thana', 'ভোলা মডেল থানা'), '01320152389': n('Dakshin Aicha (South Aicha)', 'দক্ষিণ আইচা'), '01320152415': n('Dularhat', 'দুলারহাট'),
  '01320155181': n('Patuakhali Sadar', 'পটুয়াখালী সদর'), '01320155233': n('Galachipa', 'গলাচিপা'), '01320155337': n('Mirzaganj', 'মির্জাগঞ্জ'),
  '01320155389': n('Mohipur', 'মহিপুর'), '01320153176': n('Pirojpur Sadar', 'পিরোজপুর সদর'), '01320153202': n('Nazirpur', 'নাজিরপুর'),
  '01320153332': n('Kawkhali', 'কাউখালী'), '01320156161': n('Barguna Sadar', 'বরগুনা সদর'),
  '01320117969': n('Gowainghat', 'গোয়াইনঘাট'), '01320118779': n('Habiganj Sadar', 'হবিগঞ্জ সদর'), '01320118831': n('Chunarughat', 'চুনারুঘাট'),
  '01320118909': n('Nabiganj', 'নবীগঞ্জ'), '01320119775': n('Moulvibazar Sadar', 'মৌলভীবাজার সদর'),
  '01320120790': n('Sunamganj Sadar', 'সুনামগঞ্জ সদর'), '01320120816': n('Chhatak', 'ছাতক'), '01320120868': n('Tahirpur', 'তাহিরপুর'),
  '01320121050': n('Madhyanagar', 'মধ্যনগর'), '01320121076': n('Shantiganj (South Sunamganj)', 'শান্তিগঞ্জ (দক্ষিণ সুনামগঞ্জ)'),
};
// Dhanmondi is not a model thana in either source.
NAMES['01320039548'] = n('Dhanmondi', 'ধানমন্ডি');

// Better spellings than the DGHS registry's, applied after an automatic match.
export const EN_FIX = {
  Chaddagram: 'Chauddagram', Birol: 'Biral', Shaghatta: 'Saghata', Haziganj: 'Hajiganj', Saharasthi: 'Shahrasti', Kashba: 'Kasba',
  Sulla: 'Shalla', Rowmari: 'Raumari', Nangolkot: 'Nangalkot', Monoharganj: 'Manoharganj', Dhubaura: 'Dhobaura', Gofargaon: 'Gafargaon',
  Trisal: 'Trishal', Iswarganj: 'Ishwarganj', Fulbari: 'Phulbari', Fulchari: 'Phulchari', Fulbaria: 'Phulbaria', Kahaloo: 'Kahalu',
  Chhagalnaya: 'Chhagalnaiya', Parsuram: 'Parshuram', Kownia: 'Kaunia', Moheshkhali: 'Maheshkhali', Moheshpur: 'Maheshpur',
  Modhukhali: 'Madhukhali', Charbhadrason: 'Char Bhadrasan', Tungibari: 'Tongibari', Lauhajang: 'Louhajang', Serajdikhan: 'Sirajdikhan',
  Goshairhat: 'Gosairhat', Dhupchachia: 'Dupchanchia', Abhoynagar: 'Abhaynagar', Biswambarpur: 'Bishwambarpur', Gouripur: 'Gauripur',
  Sribordi: 'Sreebardi', Fulgazi: 'Phulgazi',
};
export const BN_FIX = {
  'শ্যমনগর': 'শ্যামনগর', 'রুপগঞ্জ': 'রূপগঞ্জ', 'তালতলি': 'তালতলী', 'গংগাচড়া': 'গঙ্গাচড়া', 'টুংগীবাড়ী': 'টঙ্গীবাড়ী',
  'টুংগীপাড়া': 'টুঙ্গিপাড়া', 'ঝিনাইগাতি': 'ঝিনাইগাতী', 'লক্ষীছড়ি': 'লক্ষ্মীছড়ি',
};
