sudo add-apt-repository ppa:staticfloat/juliareleases
sudo add-apt-repository ppa:staticfloat/julia-deps
sudo apt-get update
sudo apt-get install julia
julia add_pkg.jl
sudo cp shogi.desktop /usr/share/applications/
sudo cp shogi /usr/share/applications/ -r