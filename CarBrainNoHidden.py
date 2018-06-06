import tensorflow as tf

from godot import exposed, export
from godot.bindings import *



@exposed
class CarBrainNoHidden(Node):

	def _ready(self):
		self.input_params = tf.placeholder(tf.float32, [1, 10])
		self.hidden = tf.layers.dense(inputs=self.input_params, units=10)#,activation = tf.nn.sigmoid)
		self.output = tf.layers.dense(inputs=self.hidden, units=5)#, activation = tf.nn.sigmoid)
		self.actual_v = tf.placeholder ( tf.float32, [1,5])
		self.loss = tf.losses.mean_squared_error(self.actual_v,self.output)
		self.optimizer = tf.train.GradientDescentOptimizer(0.01)
		self.train = self.optimizer.minimize(self.loss)
		self.g_output = tf.gather(self.output, 0)
		self.session = tf.Session()
		self.session.run(tf.global_variables_initializer())
		print("Tf initialized")
	
	def get_prediction(self, g_params):
		ret = self.session.run(self.g_output, feed_dict = {self.input_params : [g_params]})
		return str(ret)
	
	def train_char(self, g_params, real_values):
		self.session.run(self.train, feed_dict = {self.actual_v: [real_values], self.input_params : [g_params]})
		return str(self.session.run(self.g_output, feed_dict = {self.input_params : [g_params]})) 

