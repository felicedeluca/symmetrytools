function strip_csv_extension(str; specific_extension=".csv")
	replace(str, r"\.csv" ,"")
end

function strip_dir_name(str)
	replace(str, r".*/", "")
end

function strip_layout_label(str)
	replace(str, r".*layout","")
end
	
