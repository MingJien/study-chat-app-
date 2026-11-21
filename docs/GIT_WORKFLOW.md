# Quy trình Git cho 3 thành viên

Repo đã có `main`, `develop`, `tv1`, `tv2`, `tv3`. Dùng `develop` để ghép chức năng, `main` cho bản ổn định. Đây là điều chỉnh so với tài liệu phân công (PR thẳng main) để tận dụng nhánh develop đã có.

## 1. Đưa khung lên trước khi bắt đầu

Bản khung được chuẩn bị trên nhánh `chore/team-project-structure`. Nếu `main` và `develop` đã có khung, bỏ qua bước khởi tạo này và bắt đầu từ mục 2. Các lệnh dưới đây dành cho người tích hợp khi đưa khung lên lần đầu:

```powershell
git status
git add .github .gitignore .gitattributes .metadata README.md analysis_options.yaml android lib test docs pubspec.yaml pubspec.lock
git diff --cached --stat
git diff --cached
git commit -m "chore: add shared Flutter structure for three members"
git push -u origin chore/team-project-structure
```

Tạo PR `chore/team-project-structure → main`, review và merge. Sau khi PR đã merge, đưa khung sang develop:

```powershell
git fetch origin
git switch develop
git pull --ff-only origin develop
git merge origin/main
git push origin develop
```

Chỉ cập nhật nhánh khi working tree sạch. Kiểm tra trạng thái thực tế của các nhánh trên GitHub trước khi chạy lại bước khởi tạo. Branch protection và yêu cầu review cần được cấu hình riêng trên GitHub.

## 2. Mỗi người lấy phần của mình

Clone một lần trên máy cá nhân, không tải ZIP từng nhánh để chép đè.

```powershell
git clone https://github.com/MingJien/study-chat-app-.git study-chat-app
cd study-chat-app
git fetch origin
git switch tv1
git pull --ff-only origin tv1
git merge origin/develop
flutter pub get
```

TV2 thay `tv1` bằng `tv2`; TV3 thay bằng `tv3`. Lần đầu cả ba phải lấy được khung từ develop trước khi code.

## 3. Code, kiểm tra và push đúng đường dẫn

Ví dụ TV1:

```powershell
dart format lib/features/auth_contacts test/auth_contacts
flutter analyze
flutter test
git status
git add lib/features/auth_contacts test/auth_contacts docs/members/tv1
git diff --cached --stat
git diff --cached
git commit -m "feat(auth): implement sign-in"
git push origin tv1
```

TV2 dùng `lib/features/realtime_chat test/realtime_chat docs/members/tv2`.
TV3 dùng `lib/features/study_community test/study_community docs/members/tv3`.
Test module có thể chạy riêng bằng `flutter test test/auth_contacts` sau khi module có file test.

Không chạy formatter toàn repo trong PR module, tránh sửa hàng loạt file của người khác. Nếu stage nhầm, `git restore --staged duong/dan` chỉ bỏ stage, giữ nội dung đang làm.

Mở PR `tvN → develop`. Một người khác review phạm vi file, API, schema và kết quả test rồi mới merge. TV3 làm thay đổi app/core/dependency trong nhánh tích hợp riêng từ develop, ví dụ `integration/connect-auth`.

## 4. Cập nhật trước đợt làm tiếp theo

Sau khi commit phần đang làm:

```powershell
git fetch origin
git switch tv1
git pull --ff-only origin tv1
git merge origin/develop
flutter pub get
flutter analyze
flutter test
git push origin tv1
```

Nếu có conflict: chạy `git status`, sửa từng vùng `<<<<<<<`, `=======`, `>>>>>>>` cùng chủ file; `git add duong/dan`, `git commit`, chạy lại kiểm tra rồi push. Có thể `git merge --abort` nếu cần hủy lần merge đang dở. Không chọn toàn bộ “ours/theirs” để bỏ code của thành viên khác. Không cần force push.

## 5. Ra bản ổn định

Khi kiểm tra liên module đạt: tạo PR `develop → main`, review, merge; cả nhóm tiếp tục lấy thay đổi từ develop.

Trưởng nhóm nên bật branch protection/ruleset cho main và develop: yêu cầu PR, ít nhất một lượt approve, các check Flutter xanh và chặn force push. Đây là việc cài trên GitHub, chưa được bật bởi bản khung. Khi bật check bắt buộc, chọn các check đã thực sự chạy trên PR.

`.github/CODEOWNERS.example` chỉ là mẫu: điền GitHub username thật rồi đổi tên thành `CODEOWNERS`. Quyền sở hữu không tự chặn mọi sửa đổi; cần kết hợp review và quy tắc branch.
