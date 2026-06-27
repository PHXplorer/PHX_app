# selectpicker: returns a select element with selectpicker class and a label with `data-variable` attribute wrapped in a div with class 'custom-selectpicker'

    Code
      selectpicker(label = "test", choices = c("a", "b", "c"), selected = "b",
      data_variable = "test")
    Output
      <div class="custom-selectpicker">
        <label class="control-label" data-variable="test">test</label>
        <select class="selectpicker">
          <option>a</option>
          <option selected="">b</option>
          <option>c</option>
        </select>
      </div>

# selectpicker: sets the disabled attribute in select element to 'true' when disabled is TRUE

    Code
      selectpicker(label = "test", choices = c("a", "b", "c"), selected = "b",
      data_variable = "test", disabled = TRUE)
    Output
      <div class="custom-selectpicker">
        <label class="control-label" data-variable="test">test</label>
        <select class="selectpicker" disabled="true">
          <option>a</option>
          <option selected="">b</option>
          <option>c</option>
        </select>
      </div>

# selectpicker: adds additional attributes to select element passed to ...

    Code
      selectpicker(label = "test", choices = c("a", "b", "c"), selected = "b",
      data_variable = "test", disabled = TRUE, `additional-attribute-test` = "test")
    Output
      <div class="custom-selectpicker">
        <label class="control-label" data-variable="test">test</label>
        <select class="selectpicker" additional-attribute-test="test" disabled="true">
          <option>a</option>
          <option selected="">b</option>
          <option>c</option>
        </select>
      </div>

