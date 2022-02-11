
import '../adi.dart';
import 'keybook.dart';
import 'keypage.dart';


class KeyBookPrep {
  IdentityADI sponsorADI;
  KeyBook keybook;
  List<String> keypages;
  int timestamp;

  KeyBookPrep(this.sponsorADI, this.keybook, this.keypages, this.timestamp);

}

class KeyPagePrep {
  IdentityADI sponsorADI;
  KeyPage keypage;
  List<String> keys;
  int timestamp;

  KeyPagePrep(this.sponsorADI, this.keypage, this.keys, this.timestamp);

}