require "test_helper"

class UploadInteractionTest < RailsJsdom::TestCase
  FILES = File.expand_path("../fixtures/files", __dir__)

  test "attach_file uploads a file through a Turbo form" do
    visit new_upload_path
    attach_file "Document", "#{FILES}/hello.txt"
    click_on "Upload"

    assert_selector "#uploaded li", text: "hello.txt text/plain 6 #{Digest::MD5.hexdigest("hello\n")}"
    assert_selector "#caption", text: "Holiday"
  end

  test "attach_file keeps binary content intact" do
    visit new_upload_path
    attach_file "Document", "#{FILES}/bytes.bin"
    click_on "Upload"

    assert_selector "#uploaded li", text: "bytes.bin application/octet-stream 256 #{Digest::MD5.file("#{FILES}/bytes.bin").hexdigest}"
  end

  test "attach_file puts several files in a multiple field" do
    visit new_upload_path
    attach_file "Attachments", [ "#{FILES}/hello.txt", "#{FILES}/notes.csv" ]
    click_on "Upload"

    assert_selector "#uploaded li", count: 2
    assert_selector "#uploaded li", text: "notes.csv text/csv 4"
  end

  test "attach_file dispatches change with the chosen files" do
    visit new_upload_path
    attach_file "Document", "#{FILES}/hello.txt"

    assert_selector "#chosen", text: "hello.txt"
  end

  test "attach_file replaces the files a field already had" do
    visit new_upload_path
    attach_file "Document", "#{FILES}/hello.txt"
    attach_file "Document", "#{FILES}/notes.csv"
    click_on "Upload"

    assert_selector "#uploaded li", count: 1
    assert_selector "#uploaded li", text: "notes.csv"
  end

  test "attach_file fails with several files for a single file field" do
    visit new_upload_path

    assert_raises(RailsJsdom::Error) { attach_file "Document", [ "#{FILES}/hello.txt", "#{FILES}/notes.csv" ] }
  end

  test "attach_file uploads through a form without Turbo" do
    visit new_upload_path
    attach_file "Plain document", "#{FILES}/hello.txt"
    click_on "Upload without Turbo"

    assert_current_path "/uploads"
    assert_selector "#uploaded li", text: "hello.txt text/plain 6"
  end

  test "a form without files still submits as a Turbo form" do
    visit new_upload_path
    click_on "Upload"

    assert_selector "#caption", text: "Holiday"
    assert_no_selector "#uploaded li"
  end
end
