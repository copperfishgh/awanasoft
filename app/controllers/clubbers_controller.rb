class ClubbersController < ApplicationController
  before_filter :login_required
  layout('awana')
  
  def index
    list
    render :action => 'list'
  end

  # GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
  verify :method => :post, :only => [ :create, :update ],
         :redirect_to => { :action => :list }

  def list
    @clubbers = Clubber.find(:all, 
      :order => 'last')
    @grades = Grade.find(:all)
    session[:edit_came_from] = { :controller => 'clubbers', :action => 'list' }
  end

  def show
    @clubber = Clubber.find(params[:id])
  end

  def new
    @clubber = Clubber.new
  end

  def create
    @clubber = Clubber.new(params[:clubber])
    if @clubber.save
      flash[:notice] = 'Clubber was successfully created.'
      redirect_to :action => 'list'
    else
      render :action => 'new'
    end
  end

  def edit
    @clubber = Clubber.find(params[:id])
  end

  def back
      redirect_to session[:edit_came_from]
  end

  def update
    @clubber = Clubber.find(params[:id])
    if @clubber.update_attributes(params[:clubber])
      flash[:notice] = 'Clubber was successfully updated.'
      redirect_to session[:edit_came_from]
    else
      render :action => 'edit'
    end
  end

  def destroy
    Clubber.find(params[:id]).destroy
    redirect_to :action => 'list'
  end
end
