public without sharing class ProjectTrackerUtil {
    public static String appendLine(String existing, String line){
        String val = (existing == null || existing.trim() == '') ? line : existing + '\n' + line;
        Integer maxLen = 30000; // keep some headroom under 32,768
        if (val.length() > maxLen) {
            val = val.substring(val.length() - maxLen);
        }
        return val;
    }
}