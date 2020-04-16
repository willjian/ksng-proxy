<div class="content-wrapper">
    <!-- Main content -->
    <section class="content animated fadeInDown">
        <!-- Small boxes (Stat box) -->
        <div class="row">
            <div class="col-md-12">
                <div class=" panel-widget widget nexus-stats clearfix" style="height:455px;">
                    <div class="col-sm-12" style="height:455px;">
                        <select id="resource_change" style="border:none; background: #0683C0; color: #fff; cursor: pointer;">
                            <option value="1">60 min</option>
                            <option value="2">1 day</option>
                            <option value="3">1 month</option>
                        </select>
                        <h4 class="title">Failover resource monitor</h4>
                        <div id="line-example" class="bigchart"></div>
                        <div id="slider"></div>
                    </div>
                    <div class="right row">
                        <ul class="widget-block-list clearfix">
                            <li class="col-4">
                                <div class="block">
                                    <em class="yellow-dot"></em>
                                    <span id="resource_io">{$totalSpace}GB</span>Disk
                                </div>
                            </li>
                            <li class="col-4">
                                <div class="block">
                                    <em class="green-dot"></em>
                                    <span id="resource_mem">{$listOption[$user['plan_id']]}GB</span>Mem
                                </div>
                            </li>
                            <li class="col-4">
                                <div class="block">
                                    <em class="aqua-dot"></em>
                                    <span id="resource_cpu">{$listOption[$user['plan_id']]}vCore</span>CPU
                                </div>
                            </li>
                        </ul>
                    </div>
                </div>
            </div>
        </div><!-- /.row -->
        <!-- Start Top Stats -->
        <div class="row1">
            <div class="col-md-12 block-space1">
                <div id="sum_box" class="mbl">
                    <div class="col-sm-6 col-md-3 block-space">
                        <div class="panel db mbm gray-back">
                            <div class="panel-body">
                            <p class="description">DISK</p>
                                <h4 class="value"><span>{$data['disk'][2]}
                                    </span><span>%</span></h4>

                                <div class="progress progress-striped active mbn">
                                    <div role="progressbar" aria-valuenow="{$data['disk'][2]}" aria-valuemin="0" aria-valuemax="100"
                                        style="width: {$data['disk'][2]}%;" class="progress-bar progress-bar-success">
                                        <span class="sr-only">{$data['disk'][2]}% Complete (success)</span></div>
                                </div>
                            </div>
                        </div>
                    </div>
                    <div class="col-sm-6 col-md-3 block-space">
                        <div class="panel db mbm">
                            <div class="panel-body">
                            <p class="description">INODE</p>
                            <h4 class="value"><span>{$data['inode'][2]}</span>%<span></span></h4>
                              <div class="progress progress-striped active mbn">
                                    <div role="progressbar" aria-valuenow="{$data['inode'][2]}" aria-valuemin="0" aria-valuemax="100"
                                        style="width: {$data['inode'][2]}%;" class="progress-bar progress-bar-info">
                                        <span class="sr-only">{$data['inode'][2]}% Complete (success)</span></div>
                                </div>
                            </div>
                        </div>
                    </div>
                    <div class="col-sm-6 col-md-3 block-space gray-back">
                        <div class="panel db mbm">
                            <div class="panel-body">
                            <p class="description">PROCESS</p>
                            <h4 class="value"><span>{$data['process'][2]}</span>%</h4>
                               <div class="progress  progress-striped active mbn">
                                    <div role="progressbar" aria-valuenow="{$data['process'][2]}" aria-valuemin="0" aria-valuemax="100"
                                        style="width: {$data['process'][2]}%;" class="progress-bar progress-bar-danger">
                                        <span class="sr-only">{$data['process'][2]}% Complete (success)</span></div>
                                </div>
                            </div>
                        </div>
                    </div>
                    <div class="col-sm-6 col-md-3">
                        <div class="panel db mbm">
                            <div class="panel-body">
                            <p class="description">Website</p>
                                <h4 class="value"><span>{$websitePercent}</span>%</h4>
                                 <div class="progress  progress-striped active mbn">
                                    <div role="progressbar" aria-valuenow="{$websitePercent}" aria-valuemin="0" aria-valuemax="100"
                                        style="width: {$websitePercent}%;" class="progress-bar progress-bar-warning">
                                        <span class="sr-only">{$websitePercent}% Complete (success)</span></div>
                                </div>

                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </div>
        <!-- End Top Stats -->

         <!-- Small boxes (Stat box) -->
        <div class="row">
            <div class="col-md-12">
                <div class=" panel-widget widget nexus-stats clearfix" style="height:455px;">
                    <div class="col-sm-12" style="height:455px;">
                        <select id="mysql_change" style="border:none; background: #0683C0; color: #fff; cursor: pointer;">
                            <option value="1">60 min</option>
                            <option value="2">1 day</option>
                            <option value="3">1 month</option>
                        </select>
                        <h4 class="title">Mysql monitor</h4>
                        <div id="chart_mysql" class="bigchart"></div>
                        {* <div id="slider"></div> *}
                    </div>
                    <div class="right row">
                        <ul class="widget-block-list clearfix">
                            <li class="col-4">
                                <div class="block">
                                    <em class="yellow-dot"></em>
                                    <span id="mysql_cpu"><i class="fa fa-refresh fa-spin"></i></span>CPU 
                                </div>
                            </li>
                            <li class="col-4">
                                <div class="block">
                                    <em class="green-dot"></em>
                                    <span id="mysql_read"><i class="fa fa-refresh fa-spin"></i></span>READ 
                                </div>
                            </li>
                            <li class="col-4">
                                <div class="block">
                                    <em class="aqua-dot"></em>
                                    <span id="mysql_write"><i class="fa fa-refresh fa-spin"></i></span>Write
                                </div>
                            </li>
                        </ul>
                    </div>
                </div>
            </div>
        </div><!-- /.row -->

       
    </section><!-- /.content -->
</div>

{literal}
<style type="text/css">
    .morris-hover{position:absolute;z-index:1000}.morris-hover.morris-default-style{border-radius:10px;padding:6px;color:#666;background:rgba(255,255,255,0.8);border:solid 2px rgba(230,230,230,0.8);font-family:sans-serif;font-size:12px;text-align:center}.morris-hover.morris-default-style .morris-hover-row-label{font-weight:bold;margin:0.25em 0}
.morris-hover.morris-default-style .morris-hover-point{white-space:nowrap;margin:0.1em 0}

</style>
<script type="text/javascript">
    $(function(){
        var url = 'Home/getMonitor';
        var method = 'POST';
        var tmpData = '';
        $.ajax({
            url: url,
            type: method,
            data: {
                
            },
            beforeSend: function(){
                
            },
            success: function(result) {
                var tmpData = JSON.parse(result);
                // var lastElement = tmpData[60];
                var len = tmpData.length;
                var lastElement = tmpData[len-1];
                // console.log(lastElement);
                Morris.Line({
                  element: 'line-example',
                  resize: true,
                  data: tmpData,
                  xkey: 'y',
                  ykeys: ['a', 'b', 'c', 'd', 'e', 'f'],
                  labels: ['CPU', 'Memory', 'EP', 'Process', 'IO', 'IOPS'],
                  goals: [0,0,100],
                  units: '%',
                });

            },
            error: function(xhr, textStatus, error) {
                $('#submit-btn').button('reset');
            }
        });
    });

    $(function(){
        var url = 'Home/getMysqlMonitor';
        var method = 'POST';
        var tmpData = '';
        $.ajax({
            url: url,
            type: method,
            data: {
                
            },
            beforeSend: function(){
                
            },
            success: function(result) {
                var tmpData = JSON.parse(result);
                // var lastElement = tmpData[60];
                var len = tmpData.length;
                var lastElement = tmpData[len-1];

                Morris.Line({
                  element: 'chart_mysql',
                  resize: true,
                  data: tmpData,
                  xkey: 'y',
                  ykeys: ['a', 'b', 'c'],
                  labels: ['CPU', 'Read', 'Write',],
                  goals: [0,0,100],
                  units: '%'
                });
                $('#mysql_cpu').hide().text(lastElement.a+'%').fadeIn('slow');
                $('#mysql_read').hide().text(lastElement.b+'%').fadeIn('slow');
                $('#mysql_write').hide().text(lastElement.c+'%').fadeIn('slow');
            },
            error: function(xhr, textStatus, error) {
                $('#submit-btn').button('reset');
            }
        });
    });

    $(document).ready(function() {
        $('#resource_change').change(function(event) {
            var status = $(this).val();
            // console.log(status);
            if(status != 1 && status != 2 && status != 3){
                alert('An error occurred!');
            }else{
                var url = 'Home/getMonitor';
                var method = 'POST';
                var tmpData = '';
                $.ajax({
                    url: url,
                    type: method,
                    data: {
                        status: status,
                    },
                    beforeSend: function(){
                        
                    },
                    success: function(result) {
                        $('#line-example').empty();
                        var tmpData = JSON.parse(result);

                        var len = tmpData.length;
                        var lastElement = tmpData[len-1];
                        
                        Morris.Line({
                          element: 'line-example',
                          resize: true,
                          data: tmpData,
                          xkey: 'y',
                          ykeys: ['a', 'b', 'c', 'd', 'e', 'f'],
                          labels: ['CPU', 'Memory', 'EP', 'Process', 'IO', 'IOPS'],
                          goals: [0,0,100],
                          units: '%',
                        });

                    },
                    error: function(xhr, textStatus, error) {
                        $('#submit-btn').button('reset');
                    }
                });
            }
        });

        $('#mysql_change').change(function(event) {
            var status = $(this).val();
            // console.log(status);
            if(status != 1 && status != 2 && status != 3){
                alert('loi roi nha');
            }else{
                var url = 'Home/getMysqlMonitor';
                var method = 'POST';
                var tmpData = '';
                $.ajax({
                    url: url,
                    type: method,
                    data: {
                        status: status,
                    },
                    beforeSend: function(){
                        
                    },
                    success: function(result) {
                        $('#chart_mysql').empty();
                        var tmpData = JSON.parse(result);
                        var len = tmpData.length;
                        var lastElement = tmpData[len-1];

                        Morris.Line({
                          element: 'chart_mysql',
                          resize: true,
                          data: tmpData,
                          xkey: 'y',
                          ykeys: ['a', 'b', 'c'],
                          labels: ['CPU', 'Read', 'Write',],
                          goals: [0,0,100],
                          units: '%'
                        });
                        $('#mysql_cpu').hide().text(lastElement.a+'%').fadeIn('slow');
                        $('#mysql_read').hide().text(lastElement.b+'%').fadeIn('slow');
                        $('#mysql_write').hide().text(lastElement.c+'%').fadeIn('slow');
                    },
                    error: function(xhr, textStatus, error) {
                        $('#submit-btn').button('reset');
                    }
                });
            }
        });
    });
</script>
{/literal}