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

=begin
{
    "has_downloads": true,
    "watchers": 1,
    "clone_url": "https://github.com/danramteke/git-api-testing.git",
    "ssh_url": "git@github.com:danramteke/git-api-testing.git",
    "mirror_url": null,
    "git_url": "git://github.com/danramteke/git-api-testing.git",
    "permissions": {
      "admin": true,
      "pull": true,
      "push": true
    },
    "has_wiki": true,
    "has_issues": true,
    "forks": 1,
    "language": null,
    "fork": false,
    "description": "testing out the github api",
    "full_name": "danramteke/git-api-testing",
    "url": "https://api.github.com/repos/danramteke/git-api-testing",
    "open_issues": 0,
    "size": 0,
    "svn_url": "https://github.com/danramteke/git-api-testing",
    "private": false,
    "created_at": "2012-06-19T18:08:20Z",
    "html_url": "https://github.com/danramteke/git-api-testing",
    "pushed_at": "2012-06-19T18:08:21Z",
    "owner": {
      "login": "danramteke",
      "avatar_url": "https://secure.gravatar.com/avatar/0f332eefb17d62070ae45b89a5784617?d=https://a248.e.akamai.net/assets.github.com%2Fimages%2Fgravatars%2Fgravatar-140.png",
      "url": "https://api.github.com/users/danramteke",
      "gravatar_id": "0f332eefb17d62070ae45b89a5784617",
      "id": 15749
    },
    "name": "git-api-testing",
    "homepage": null,
    "id": 4717348,
    "updated_at": "2012-06-19T18:08:21Z"
  }





  SOLO:fv cyrus$ curl -H "Authorization: bearer 5e645e5ee8b31090db53a059e0d7f2da93c8053b" https://api.github.com/repos/danramteke/git-api-testing/git/refs/heads/master
{
  "object": {
    "type": "commit",
    "url": "https://api.github.com/repos/danramteke/git-api-testing/git/commits/769ea73f4a9713783e42de3cc617c597db304275",
    "sha": "769ea73f4a9713783e42de3cc617c597db304275"
  },
  "url": "https://api.github.com/repos/danramteke/git-api-testing/git/refs/heads/master",
  "ref": "refs/heads/master"
}









SOLO:fv cyrus$ curl -H "Authorization: bearer 5e645e5ee8b31090db53a059e0d7f2da93c8053b" https://api.github.com/repos/danramteke/git-api-testing/git/trees/769ea73f4a9713783e42de3cc617c597db304275
{
  "url": "https://api.github.com/repos/danramteke/git-api-testing/git/trees/769ea73f4a9713783e42de3cc617c597db304275",
  "tree": [
    {
      "url": "https://api.github.com/repos/danramteke/git-api-testing/git/blobs/cb66371e43311edb901329b309b3ce8abc3a1bed",
      "type": "blob",
      "sha": "cb66371e43311edb901329b309b3ce8abc3a1bed",
      "size": 59,
      "path": "README.md",
      "mode": "100644"
    }
  ],
  "sha": "769ea73f4a9713783e42de3cc617c597db304275"
}










SOLO:fv cyrus$ curl -H "Authorization: bearer 5e645e5ee8b31090db53a059e0d7f2da93c8053b" https://api.github.com/repos/danramteke/git-api-testing/git/blobs/cb66371e43311edb901329b309b3ce8abc3a1bed
{
  "content": "Z2l0LWFwaS10ZXN0aW5nCj09PT09PT09PT09PT09PQoKdGVzdGluZyBvdXQg\ndGhlIGdpdGh1YiBhcGk=\n",
  "url": "https://api.github.com/repos/danramteke/git-api-testing/git/blobs/cb66371e43311edb901329b309b3ce8abc3a1bed",
  "size": 59,
  "sha": "cb66371e43311edb901329b309b3ce8abc3a1bed",
  "encoding": "base64"
}




SOLO:fv cyrus$ curl  -d '{"content": "so much content", "encoding": "utf-8"}' -H "Authorization: bearer 5e645e5ee8b31090db53a059e0d7f2da93c8053b" https://api.github.com/repos/danramteke/git-api-testing/git/blobs
{
  "url": "https://api.github.com/repos/danramteke/git-api-testing/git/blobs/c0810c84695544dca65308c454a7ef2227b12975",
  "sha": "c0810c84695544dca65308c454a7ef2227b12975"
}




SOLO:fv cyrus$ curl  -d '{ "tree": [ { "path": "file.rb", "mode": "100644", "type": "blob", "sha": "c0810c84695544dca65308c454a7ef2227b12975" } ] }' -H "Authorization: bearer 5e645e5ee8b31090db53a059e0d7f2da93c8053b" https://api.github.com/repos/danramteke/git-api-testing/git/trees
{
  "url": "https://api.github.com/repos/danramteke/git-api-testing/git/trees/c212664aef0bffdf9981d86f3d494887f001604c",
  "sha": "c212664aef0bffdf9981d86f3d494887f001604c",
  "tree": [
    {
      "type": "blob",
      "url": "https://api.github.com/repos/danramteke/git-api-testing/git/blobs/c0810c84695544dca65308c454a7ef2227b12975",
      "size": 15,
      "sha": "c0810c84695544dca65308c454a7ef2227b12975",
      "path": "file.rb",
      "mode": "100644"
    }
  ]
}



=end
