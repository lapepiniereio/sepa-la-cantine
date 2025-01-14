import 'package:xml/xml.dart';

class SepaService {
  bool isValidSepaFile(XmlDocument document) {
    try {
      final root = document.rootElement;
      if (root.name.local != 'Document') return false;

      final transfer = root.findElements('CstmrCdtTrfInitn');
      if (transfer.isEmpty) return false;

      final pmtInf = transfer.first.findElements('PmtInf');
      if (pmtInf.isEmpty) return false;

      return true;
    } catch (e) {
      return false;
    }
  }

  bool isAlreadyInstant(XmlDocument document) {
    try {
      final pmtInfElements = document.findAllElements('PmtInf');
      for (var pmtInf in pmtInfElements) {
        final pmtTpInf = pmtInf.findElements('PmtTpInf').firstOrNull;
        if (pmtTpInf != null) {
          final lclInstrm = pmtTpInf.findElements('LclInstrm').firstOrNull;
          if (lclInstrm != null) {
            final cd = lclInstrm.findElements('Cd').firstOrNull;
            if (cd != null && cd.text == 'INST') {
              return true;
            }
          }
        }
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  void convertToInstantSepa(XmlDocument document) {
    final pmtInfElements = document.findAllElements('PmtInf');

    for (var pmtInf in pmtInfElements) {
      var pmtTpInf = pmtInf.findElements('PmtTpInf').firstOrNull;
      if (pmtTpInf == null) {
        pmtTpInf = XmlElement(XmlName('PmtTpInf'));
        final reqdExctnDt = pmtInf.findElements('ReqdExctnDt').firstOrNull;
        if (reqdExctnDt != null) {
          final index = pmtInf.children.indexOf(reqdExctnDt);
          pmtInf.children.insert(index + 1, pmtTpInf);
        } else {
          pmtInf.children.insert(0, pmtTpInf);
        }
      }

      var svcLvl = pmtTpInf.findElements('SvcLvl').firstOrNull;
      if (svcLvl == null) {
        svcLvl = XmlElement(XmlName('SvcLvl'));
        pmtTpInf.children.add(svcLvl);
      } else {
        svcLvl.children.clear();
      }
      final svcLvlCd = XmlElement(XmlName('Cd'));
      svcLvlCd.children.add(XmlText('SEPA'));
      svcLvl.children.add(svcLvlCd);

      var lclInstrm = pmtTpInf.findElements('LclInstrm').firstOrNull;
      if (lclInstrm == null) {
        lclInstrm = XmlElement(XmlName('LclInstrm'));
        pmtTpInf.children.add(lclInstrm);
      } else {
        lclInstrm.children.clear();
      }
      final lclInstrmCd = XmlElement(XmlName('Cd'));
      lclInstrmCd.children.add(XmlText('INST'));
      lclInstrm.children.add(lclInstrmCd);
    }
  }
}
