require "net/https"
require "uri"
require 'json'
require 'base64'

require 'pp'


def do_get(rest_of_path)
	do_request(Net::HTTP::Get, rest_of_path)
end

def do_post(rest_of_path, form_data)
	do_request(Net::HTTP::Post, rest_of_path, form_data)
end

def do_patch(rest_of_path, form_data)
  do_request(Net::HTTP::Patch, rest_of_path, form_data)
end
def do_request(requester, rest_of_path, form_data=nil)
	uri = URI.parse("https://api.github.com#{rest_of_path}")
	http = Net::HTTP.new(uri.host, uri.port)
	http.use_ssl = true
	http.verify_mode = OpenSSL::SSL::VERIFY_NONE

	request = requester.new(uri.request_uri)
	request["Authorization"]= "bearer 5e645e5ee8b31090db53a059e0d7f2da93c8053b"
	unless form_data.nil?
		request.body = form_data.to_json 
		request.content_type = "application/json; charset=utf-8"
	end
		
	response = http.request(request)

  if (rest_of_path.match(/commit/))
  	puts response.inspect
  end

	JSON.parse(response.body)
end

def get_master_listing
	result = do_get("/repos/danramteke/git-api-testing/git/refs/heads/master")
	# puts "Current Master commit sha is #{result["object"]["sha"]}"
	result["object"]["sha"]
end


def tree_for_sha(sha)
	result = do_get("/repos/danramteke/git-api-testing/git/trees/#{sha}")
	# pp result
	result
end

def file_contents(filename, tree_sha)
	tree_obj = tree_for_sha(tree_sha)
	blob_sha = tree_obj["tree"].find{|object| object["path"] == filename}["sha"]
	blob_contents(blob_sha)
end

def blob_contents(blob_sha)
	result = do_get("/repos/danramteke/git-api-testing/git/blobs/#{blob_sha}")
	contents_without_newlines = result["content"].gsub(/\n/, "")
	Base64.decode64 contents_without_newlines
end

def create_blob(contents) 
	result = do_post("/repos/danramteke/git-api-testing/git/blobs", {'content' => contents, 'encoding' => 'utf-8'})
	pp result
end

def create_tree(blob_sha, path)
	# "tree": [ { "path": "file.rb", "mode": "100644", "type": "blob", "sha": "c0810c84695544dca65308c454a7ef2227b12975" } ]
	tree = {"tree" => [{
		"path" => path,
		"mode" => "100644", 
		"type" => "blob",
		"sha" => blob_sha
	}]}

	result = do_post("/repos/danramteke/git-api-testing/git/trees", tree)
	pp result
end

def create_commit(message, parent, tree)
  commit = {
    message: message,
    parents: [parent],
    tree: tree
  }
 
  result = do_post("/repos/danramteke/git-api-testing/git/commits", commit)
  pp result
end

def create_reference(ref_string, new_ref_sha)
  reference = {
    ref: ref_string,
    sha: new_ref_sha
  }

  result = do_post("/repos/danramteke/git-api-testing/git/refs", reference)
  pp result
end

def update_reference(new_ref_sha)
  reference = {
    sha: new_ref_sha
  }

  result = do_patch("/repos/danramteke/git-api-testing/git/refs/heads/master", reference)
  pp result
end


master_commit_sha = get_master_listing()
# tree_for_sha(master_commit_sha)

# pp file_contents("README.md", master_commit_sha)

#new objects
BLOB_SHA = "8639803cb6f347c70f3d71cad5f8c4854196fb80" # create_blob("this is a blob of stuff for things")
TREE_SHA = "1f510192324b45dfc0c1c2d9ee99d0f9cd604a05" #create_tree(BLOB_SHA)
# puts blob_contents(BLOB_SHA)
# pp "My Tree", tree_for_sha(TREE_SHA)
# pp "Master", tree_for_sha("78f5cec8b0ac079501070b20e2b672bbf282adbd")
# result = create_commit("I can haz commits", "78f5cec8b0ac079501070b20e2b672bbf282adbd", TREE_SHA)
# update_reference("a6f8d49765794c6c21b436cfd986cba232eefe86")


blob_sha = create_blob(File.read("https_spike.rb"))["sha"]
tree_sha = create_tree(blob_sha, "github-api-notes.rb")["sha"]
commit_sha = create_commit("posting my notes", master_commit_sha, tree_sha)["sha"]
update_reference(commit_sha)

