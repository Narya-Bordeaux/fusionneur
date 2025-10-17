// Service qui écrit les SECTION markers réels avant JSON index et CODE section.

class SectionMarkersWriter {
  const SectionMarkersWriter();

  void writeJsonIndexMarker(StringSink out) {
    out.writeln('::FUSION::SECTION:JSON_INDEX');
  }

  void writeCodeSectionMarker(StringSink out) {
    out.writeln('::FUSION::SECTION:CODE');
  }
}
