module server

import lsp
import jsonrpc
import json112

fn (mut ls Vls112) definition(id string, params string)?{

	req_params := json112.decode(params) or {
		ls.logger.error('definition-->',0)?
		ls.logger.text(err.str(),0,'\t')?
		return err
	}

	node_source_uri := json112.node('textDocument.uri')
	node_position_character := json112.node('position.line')
	node_position_line := json112.node('position.character')
	
	if!(req_params.exist(node_source_uri) && req_params.exist(node_position_character) && req_params.exist(node_position_line)){
		return
	}

	if!(req_params.typ(node_source_uri) == .string && req_params.typ(node_position_character) == .number && req_params.typ(node_position_line) == .number){
		return
	}

	source_path := uri_to_path(req_params.val<string>(node_source_uri))
	position_character := int(req_params.val<f64>(node_position_character))
	position_line := int(req_params.val<f64>(node_position_line))

	// ls.logger.info('source_path-->',0)?
	// ls.logger.text(source_path,0,'\t')?
	// ls.logger.info('position_character-->',0)?
	// ls.logger.text(position_character,0,'\t')?
	// ls.logger.info('position_line-->',0)?
	// ls.logger.text(position_line,0,'\t')?
	
	//step 1 获取鼠标选中目标的名字

















	loc_uri := lsp.document_uri_from_path(r'c:\Users\zhangjianguo\Desktop\test7\test7.v')
	target_range := new_range(0,0,6,0)
	target_selection_range := new_range(2,0,2,8)
	origin_selection_range := new_range(8,0,9,0)

	df_location := jsonrpc.Response<lsp.LocationLink>{
		id: id
		result: lsp.LocationLink{
			target_uri: loc_uri
			target_range: target_range  //目标函数的总体范围 用于突出显示
			target_selection_range: target_selection_range  //跳转后目标函数所选中的区域
			origin_selection_range: origin_selection_range  //源单词的跨度
		}
	}
	ls.send(df_location)?
}

fn new_range(start_line int,start_character int,end_line int,end_character int)lsp.Range{
	return lsp.Range{
		start: lsp.Position{
			line:start_line
			character:start_character
		}
		end: lsp.Position{
			line:end_line
			character:end_character
		}
	}
}

fn goto_definition