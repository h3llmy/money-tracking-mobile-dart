void main() {
  final base = Uri.parse('http://192.168.1.222:5008/api/v1');
  final pathLeadingSlash = base.resolve('/auth/login');
  final pathNoLeadingSlash = base.resolve('auth/login');
  
  print('With leading slash: $pathLeadingSlash');
  print('Without leading slash: $pathNoLeadingSlash');
}
